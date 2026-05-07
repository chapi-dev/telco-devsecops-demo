// Package v1alpha1 contains the API types for the demo Network Function CRD.
//
// The CRD is a placeholder — its only purpose is to demonstrate that
// Kubernetes Operator code, CRDs and reconcilers live alongside Helm charts
// in the same GitHub repo, all PR-gated and CI-validated.
//
// +kubebuilder:object:generate=true
// +groupName=nf.telco-demo.io
package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

var (
	GroupVersion  = schema.GroupVersion{Group: "nf.telco-demo.io", Version: "v1alpha1"}
	SchemeBuilder = runtime.NewSchemeBuilder(addKnownTypes)
	AddToScheme   = SchemeBuilder.AddToScheme
)

func addKnownTypes(scheme *runtime.Scheme) error {
	scheme.AddKnownTypes(GroupVersion,
		&NetworkFunction{},
		&NetworkFunctionList{},
	)
	metav1.AddToGroupVersion(scheme, GroupVersion)
	return nil
}

// NetworkFunctionSpec defines the desired state of a NetworkFunction.
type NetworkFunctionSpec struct {
	// Type is the 3GPP NF type (UPF, AMF, SMF, NRF, ...).
	Type string `json:"type"`
	// Replicas is the number of NF instances.
	Replicas int32 `json:"replicas,omitempty"`
	// Image is the container image of the NF.
	Image string `json:"image"`
}

// NetworkFunctionStatus defines the observed state.
type NetworkFunctionStatus struct {
	Phase              string `json:"phase,omitempty"`
	ObservedGeneration int64  `json:"observedGeneration,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status

// NetworkFunction is the Schema for the networkfunctions API.
type NetworkFunction struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   NetworkFunctionSpec   `json:"spec,omitempty"`
	Status NetworkFunctionStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// NetworkFunctionList contains a list of NetworkFunction.
type NetworkFunctionList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []NetworkFunction `json:"items"`
}

// DeepCopyInto copies the receiver into out. (controller-gen would generate this.)
func (in *NetworkFunction) DeepCopyInto(out *NetworkFunction) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ObjectMeta.DeepCopyInto(&out.ObjectMeta)
	out.Spec = in.Spec
	out.Status = in.Status
}

// DeepCopy returns a deep copy of NetworkFunction.
func (in *NetworkFunction) DeepCopy() *NetworkFunction {
	if in == nil {
		return nil
	}
	out := new(NetworkFunction)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject implements runtime.Object.
func (in *NetworkFunction) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto copies the receiver into out.
func (in *NetworkFunctionList) DeepCopyInto(out *NetworkFunctionList) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ListMeta.DeepCopyInto(&out.ListMeta)
	if in.Items != nil {
		out.Items = make([]NetworkFunction, len(in.Items))
		for i := range in.Items {
			in.Items[i].DeepCopyInto(&out.Items[i])
		}
	}
}

// DeepCopy returns a deep copy of NetworkFunctionList.
func (in *NetworkFunctionList) DeepCopy() *NetworkFunctionList {
	if in == nil {
		return nil
	}
	out := new(NetworkFunctionList)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject implements runtime.Object.
func (in *NetworkFunctionList) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}
