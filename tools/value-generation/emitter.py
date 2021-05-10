import textwrap
import yaml
from yaml.emitter import Emitter
from yaml.serializer import Serializer 
from yaml.representer import SafeRepresenter
from yaml.nodes import Node, ScalarNode, MappingNode
from collections.abc import Mapping, MutableMapping

class CommentedMapping(MutableMapping):
    def __init__(self, d, comment=None, comments={}):
        self.mapping = d
        self.comment = comment
        self.comments = comments

    def get_comment(self, *path):
        if not path:
            return self.comment

        # Look the key up in self (recursively) and raise a
        # KeyError or other execption if such a key does not
        # exist in the nested structure
        sub = self.mapping
        for p in path:
            if isinstance(sub, CommentedMapping):
                # Subvert comment copying
                sub = sub.mapping[p]
            else:
                sub = sub[p]

        comment = None
        if len(path) == 1:
            comment = self.comments.get(path[0])
        if comment is None:
            comment = self.comments.get(path)
        return comment

    def __getitem__(self, item):
        val = self.mapping[item]
        if (isinstance(val, (dict, Mapping)) and
                not isinstance(val, CommentedMapping)):
            comment = self.get_comment(item)
            comments = {k[1:]: v for k, v in self.comments.items()
                        if isinstance(k, tuple) and len(k) > 1 and k[0] == item}
            val = self.__class__(val, comment=comment, comments=comments)
        return val

    def __setitem__(self, item, value):
        self.mapping[item] = value

    def __delitem__(self, item):
        del self.mapping[item]
        for k in list(self.comments):
            if k == item or (isinstance(k, tuple) and k and k[0] == item):
                del self.comments[key]

    def __iter__(self):
        return iter(self.mapping)

    def __len__(self):
        return len(self.mapping)

    def __repr__(self):
        return f'{type(self).__name__}({self.mapping}, comment={self.comment!r}, comments={self.comments})'


class CommentedNode(Node):
    """Dummy base class for all nodes with attached comments."""


class CommentedScalarNode(ScalarNode, CommentedNode):
    def __init__(self, tag, value, start_mark=None, end_mark=None, style=None,
                 comment=None):
        super().__init__(tag, value, start_mark, end_mark, style)
        self.comment = comment


class CommentedMappingNode(MappingNode, CommentedNode):
    def __init__(self, tag, value, start_mark=None, end_mark=None,
                 flow_style=None, comment=None, comments={}):
        super().__init__(tag, value, start_mark, end_mark, flow_style)
        self.comment = comment
        self.comments = comments

class CommentedRepresenter(SafeRepresenter):
    def represent_commented_mapping(self, data):
        node = super().represent_dict(data)
        comments = {k: data.get_comment(k) for k in data}
        value = []
        for k, v in node.value:
            if k.value in comments:
                k = CommentedScalarNode(
                        k.tag, k.value,
                        k.start_mark, k.end_mark, k.style,
                        comment=comments[k.value])
            value.append((k, v))

        node = CommentedMappingNode(
            node.tag,
            value,
            flow_style=False,  # commented dicts must be in block style
                               # this could be implemented differently for flow-style
                               # maps, but for my case I only want block-style, and
                               # it makes things much simpler
            comment=data.get_comment(),
            comments=comments
        )
        return node

    yaml_representers = SafeRepresenter.yaml_representers.copy()
    yaml_representers[CommentedMapping] = represent_commented_mapping


class CommentEvent(yaml.Event):
    """
    Simple stream event representing a comment to be output to the stream.
    """
    def __init__(self, value, start_mark=None, end_mark=None):
        super().__init__(start_mark, end_mark)
        self.value = value

class CommentedSerializer(Serializer):
    def serialize_node(self, node, parent, index):
        if (node not in self.serialized_nodes and
                isinstance(node, CommentedNode) and
                not (isinstance(node, CommentedMappingNode) and
                     isinstance(parent, CommentedMappingNode))):
            # Emit CommentEvents, but only if the current node is not a
            # CommentedMappingNode nested in another CommentedMappingNode (in
            # which case we would have already emitted its comment via the
            # parent mapping)
            self.emit(CommentEvent(node.comment))

        super().serialize_node(node, parent, index)

class CommentedEmitter(Emitter):
    def need_more_events(self):
        if self.events and isinstance(self.events[0], CommentEvent):
            # If the next event is a comment, always break out of the event
            # handling loop so that we divert it for comment handling
            return True
        return super().need_more_events()

    def need_events(self, count):
        # Hack-y: the minimal number of queued events needed to start
        # a block-level event is hard-coded, and does not account for
        # possible comment events, so here we increase the necessary
        # count for every comment event
        comments = [e for e in self.events if isinstance(e, CommentEvent)]
        return super().need_events(count + min(count, len(comments)))

    def emit(self, event):
        if self.events and isinstance(self.events[0], CommentEvent):
            # Write the comment, then pop it off the event stream and continue
            # as normal
            self.write_comment(self.events[0].value)
            self.events.pop(0)

        super().emit(event)

    def write_comment(self, comment):
        indent = self.indent or 0
        width = self.best_width - indent - 2  # 2 for the comment prefix '# '
        if comment is not None:
            lines = ['# ' + line for line in textwrap.wrap(comment, width)]

            for line in lines:
                if self.encoding:
                    line = line.encode(self.encoding)
                self.write_indent()
                self.stream.write(line)
                self.write_line_break()


class CommentedDumper(CommentedEmitter, CommentedSerializer,
                      CommentedRepresenter, yaml.SafeDumper):
    """
    Extension of `yaml.SafeDumper` that supports writing `CommentedMapping`s with
    all comments output as YAML comments.
    """

