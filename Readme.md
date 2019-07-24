= Helm Guide for the Couchbase Operator

[abstract]
https://helm.sh/[Helm^] is a tool that streamlines the installation and management of applications on Kubernetes platforms.
Official Couchbase Helm charts can help you easily set up the Couchbase Autonomous Operator.

This page describes how to set up Helm to properly support the Couchbase Autonomous Operator in your Kubernetes environment.
Setting up Helm consists of installing the Helm client (`helm`) on your computer, and installing the Helm server (Tiller) on your Kubernetes cluster.
Once you've set up Helm, you can then use official Couchbase Helm charts to deploy the Operator and the Couchbase Server cluster.

== Installing Helm

=== Install the Helm Client

Follow Helm's https://docs.helm.sh/using_helm/#installing-helm[official steps^] for installing `helm` on your operating system.

It's helpful to install `helm` on the same computer where you normally run `kubectl`.

[#install-tiller]
=== Install the Helm Server (Tiller)

After you’ve installed `helm`, you'll need to install Tiller — the server portion of Helm that runs inside of your Kubernetes cluster.

Follow Helm's https://docs.helm.sh/using_helm/#installing-tiller[official steps^] for installing Tiller on your Kubernetes cluster.

==== Installing Tiller for Development

For development use-cases, the Tiller service can be given access to deploy charts into any namespace of your Kubernetes cluster.
This also means that resources created by the chart, such as the custom resource definition (CRD), are allowed when Tiller is given this level of privilege.

To create RBAC rules for Tiller with cluster-wide access, refer to the Helm documentation about https://docs.helm.sh/using_helm/#example-service-account-with-cluster-admin-role[deploying Tiller with the cluster-admin role^].

==== Installing Tiller for Production

For production use cases, it's recommended that you restrict the Tiller service to deploying charts only into namespaces that will be used by Helm.
This ensures that your applications are operating in the scope that you've specified.

To create RBAC rules for Tiller that have restricted access, refer to the Helm documentation about deploying Tiller in a namespace such that it's https://docs.helm.sh/using_helm/#example-deploy-tiller-in-a-namespace-restricted-to-deploying-resources-only-in-that-namespace[restricted to deploying resources only in that namespace^].

IMPORTANT: When Tiller is restricted to a single namespace, the Operator won't be able to automatically install the custom resource definition (CRD) that's required to create Couchbase clusters.
See the <<deploy-production,production deployment instructions>> for information about manually installing the CRD.

== Deploying the Operator and Couchbase Server

Two Helm https://docs.helm.sh/using_helm/#three-big-concepts[charts^] are available for deploying Couchbase.
The xref:helm-operator-config.adoc[Couchbase Operator Chart] deploys the admission controller and the Operator itself.
The xref:helm-cluster-config.adoc[Couchbase Cluster Chart] deploys the Couchbase Server cluster.

For production deployments, you'll only use the Operator Chart.
For development environments, the Couchbase Cluster Chart is available to help you quickly set up a test cluster.

=== Deploying for Development (Quick Start)

To quickly deploy the admission controller and Operator, as well as a Couchbase Server cluster for development purposes:

. Add the chart repository to `helm`:
+
[source,console]
----
helm repo add couchbase https://couchbase-partners.github.io/helm-charts/
----
. Install the Operator Chart:
+
[source,console]
----
helm install couchbase/couchbase-operator
----
. Install the Couchbase Cluster Chart:
+
[source,console]
----
helm install couchbase/couchbase-cluster
----

[#deploy-production]
=== Deploying for Production

For production deployments, additional customization is required in order to restrict the RBAC roles of the Operator to a single namespace.
Note that this restriction requires that the CRD be manually created.
This is because the CRD is a cluster-wide resource and cannot be created by the Operator when it has restricted access.

The following steps show the minimum requirements for deploying the Operator Chart under the above constraints for production usage:

. Download the Operator https://www.couchbase.com/downloads[package^] and unpack it on the same computer where you normally run `kubectl`.
. Included in the package is a file called `crd.yaml`.
Use the following command to add it to your Kubernetes cluster:
+
[source,console]
----
kubectl create -f crd.yaml
----
. Add the chart repository to `helm`:
+
[source,console]
----
helm repo add couchbase https://couchbase-partners.github.io/helm-charts/
----
. Install the Operator Chart:
+
[source,console]
----
helm install --set rbac.clusterRoleAccess=false couchbase/couchbase-operator
----
+
The above command uses the `--set` option to override the chart's default `rbac.clusterRoleAccess` parameter and sets it to `false`.
This is the most important parameter to modify for production environments.
However, you may need to override additional parameters to meet the needs of your environment.
Therefore, it's recommended that you keep all of your overrides in a YAML file, and use the the `--values` option instead of the `--set` option when you install.
See <<customize-charts,Customizing Helm Charts>> for more information.
+
[NOTE]
====
When you install a chart, Helm autogenerates a name for the https://docs.helm.sh/glossary/#release[release^] (usually a unique set of dictionary words).
Helm prepends this name to all of the objects and resources that the chart creates.

If you plan to use Helm to install multiple instances of the Operator, you should consider giving each release a unique name to help you more easily identify the resources that are associated with each release.
You can specify a name for the release during chart installation by using the `--name` flag:

[source,console]
----
helm install -n <unique-name> --set rbac.clusterRoleAccess=false couchbase/couchbase-operator
----
====
. Deploy the Couchbase Server cluster using the xref:deploying-couchbase.adoc[traditional method].
+
Note that you're not deploying the Couchbase cluster using a Helm chart.
Due to the complex structure of production configurations (which usually include server groups and persistent volumes), Couchbase clusters are better expressed and managed directly using a cluster spec.

[#customize-charts]
=== Customizing Helm Charts

The official Couchbase Helm charts are great to use "as-is" for quickly deploying Couchbase on Kubernetes, but you'll undoubtedly need to customize them for your specific development and production needs.
All of the values that are exposed by the charts are available within the `values.yaml` file of the xref:helm-operator-config.adoc[Couchbase Operator Chart] and the xref:helm-cluster-config.adoc[Couchbase Cluster Chart].

You can customize each chart by using https://docs.helm.sh/using_helm/#customizing-the-chart-before-installing[overrides^].
There are two methods to specify overrides during chart installation: `--values` and `--set`.

[{tabs}]
====
--values::
+
--
The `--values` option is the preferred method because it allows you to keep your overrides in a YAML file, rather than specifying them all on the command line.

. Create a YAML file and add your overrides to it.
Here's an example called `myvalues.yaml`:
+
[source,yaml]
----
couchbaseOperator:
  imagePullPolicy: Always
----
. Specify your overrides file when you install the chart:
+
[source,console]
----
helm install --values myvalues.yaml couchbase/coucbase-operator
----
+
The values in your overrides file (`myvalues.yaml`) will override their counterparts in the chart's `values.yaml` file.
Any values in `values.yaml` that weren't overridden will keep their defaults.
--

--set::
+
--
If you only need to make minor customizations, you can specify them on the command line by using the `--set` option.
Here's an example:

[source,console]
----
helm install --set rbac.clusterRoleAccess=false couchbase/couchbase-operator
----

This would translate to the following in the `values.yaml` of the chart:

[source,yaml]
----
rbac:
  clusterRoleAccess: true
----
--
====

For more information about each chart, see the following:

* Operator Chart
 ** xref:helm-operator-config.adoc[Documentation]
 ** https://github.com/couchbase-partners/helm-charts/tree/master/couchbase-operator[GitHub^]
* Couchbase Cluster Chart
 ** xref:helm-cluster-config.adoc[Documentation]
 ** https://github.com/couchbase-partners/helm-charts/tree/master/couchbase-cluster[GitHub^]

=== Chart Versions

The `helm install` command will always pull the highest version of a chart.
To list the versions of the chart that are available for installation, you can run the `helm search` command:

[source,console]
----
helm search --versions couchbase/couchbase-operator
----

[source,console]
----
NAME                        	CHART VERSION	APP VERSION	DESCRIPTION
couchbase/couchbase-operator	0.1.2        	1.2        	A Helm chart for Kubernetes
----

Here, the `CHART VERSION` is *0.1.2*, and the `APP VERSION` (the Couchbase Operator version) is *1.2*.

To install a specific version of a chart, include the `--version` argument when installing:

[source,console]
----
helm install --version 0.1.2 couchbase/couchbase-operator
----

[TIP]
====
If you're having trouble finding or installing a specific version of a chart, use the `helm repo update` command to ensure that you have the latest list of charts.
====

== Updating a Helm Chart After Installation

When you install a Helm chart, Tiller (the Helm server) creates an instance of that chart in your Kubernetes cluster.
This instance is called a _release_, and Tiller uses it to track all of the objects and resources that the chart creates.

After installation, you may find yourself needing to make updates to the Operator configuration.
Similar to installing the chart, customizations are made in the form of overrides via the <<customize-charts,--values or --set options>>.
However, instead of `helm install`, you'll be using `helm upgrade`.
Here's an example:

[source,console]
----
helm upgrade --values myvalues.yaml <release-name>
----

It's important that you make your updates using the `helm upgrade` command, as opposed to using kubectl or simply editing chart resources.
This is to ensure that all resources are updated appropriately.

=== Upgrading with Helm Charts

Upgrading the Operator to a newer version requires that you upgrade the _release_ to a newer version of its _chart_.
Again, this is to ensure that any other dependencies related to the Operator upgrade are also updated appropriately.

.To upgrade the Operator using Helm:
[source,console]
----
helm upgrade --version <version> <release-name> couchbase/couchbase-operator
----

Here, `<version>` is the version of the chart that you want to upgrade to, and  `<release-name>` is the name of the release that is managing the instance of the Operator that you are trying to upgrade.

Refer to the xref:upgrading-the-operator.ado[Operator upgrade documentation] for more information about the upgrade process.

IMPORTANT: If you didn't originally install the Operator using Helm, then you cannot upgrade the Operator using Helm.
At this time, Operator installations that weren't created with Helm cannot be ported over to using Helm.
