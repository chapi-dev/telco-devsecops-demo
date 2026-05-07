// Package controllers implements the NetworkFunction reconciler stub.
package controllers

import (
	"context"

	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	nfv1alpha1 "github.com/chapi-dev/telco-devsecops-demo/src/demo-nf/api/v1alpha1"
)

// NetworkFunctionReconciler reconciles a NetworkFunction object.
type NetworkFunctionReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=nf.telco-demo.io,resources=networkfunctions,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=nf.telco-demo.io,resources=networkfunctions/status,verbs=get;update;patch

// Reconcile is the placeholder reconcile loop.
func (r *NetworkFunctionReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx).WithValues("networkfunction", req.NamespacedName)

	var nf nfv1alpha1.NetworkFunction
	if err := r.Get(ctx, req.NamespacedName, &nf); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	logger.Info("reconcile", "type", nf.Spec.Type, "replicas", nf.Spec.Replicas, "image", nf.Spec.Image)

	if nf.Status.Phase != "Ready" {
		nf.Status.Phase = "Ready"
		nf.Status.ObservedGeneration = nf.Generation
		if err := r.Status().Update(ctx, &nf); err != nil {
			return ctrl.Result{}, err
		}
	}
	return ctrl.Result{}, nil
}

// SetupWithManager wires the reconciler into a controller-runtime manager.
func (r *NetworkFunctionReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&nfv1alpha1.NetworkFunction{}).
		Complete(r)
}
