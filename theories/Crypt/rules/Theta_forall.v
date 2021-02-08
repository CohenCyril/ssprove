From Mon Require Import
     FiniteProbabilities
     SPropMonadicStructures
     SpecificationMonads
     MonadExamples
     SPropBase
     SRelationClasses
     SMorphisms
     FiniteProbabilities.

From Relational Require Import
     OrderEnrichedCategory
     OrderEnrichedRelativeMonadExamples
     Commutativity.
From mathcomp Require Import
     all_ssreflect
     all_algebra
     reals
     distr
     realsum.
From Crypt Require Import
     Axioms
     ChoiceAsOrd
     SubDistr
     Couplings.

Import SPropNotations.
Import Num.Theory.

Notation "⟦ b ⟧" := (is_true_sprop b).
Infix "-s>" := (s_impl) (right associativity, at level 86, only parsing).

Local Open Scope ring_scope.

(* CA's TODO:

   Define θ: SDistr × SDistr ==> ×; Cont_Prop


   θ {A1 A2 : ChType} (c1 : A1 -> I, c2 : A2 -> I) =

         λ (π : A1 × A2 -> Prop) =

               ∀ d ~ < c1, c2 >. ∃ (a1 : A1) (a2 : A2). π (a1, a2) /\ d(a1, a2) > 0

    CA's math intuition: ∀ d ~ < c1, c2 >. ∫_{π} d > 0

         the expected value when sampling using d from the set of
         points that are in the relation π is not 0.

         if we imagine π as describing a good event, we are saying that
         such a good event always happens no matter which coupling we pick

 *)

Definition F_choice_prod_obj : Obj (prod_cat ord_choiceType ord_choiceType) ->
                               Obj ord_choiceType.
Proof.
  rewrite /prod_cat /=. move => [C1 C2].
  exact (prod_choiceType C1 C2).
Defined.

Definition F_choice_prod_morph : forall T1  T2 : (prod_cat ord_choiceType ord_choiceType),
    (prod_cat ord_choiceType ord_choiceType) ⦅ T1; T2 ⦆ ->
    ord_choiceType ⦅F_choice_prod_obj T1; F_choice_prod_obj T2 ⦆.
Proof.
  move => [C11 C12] [C21 C22] [f1 f2] [c1 c2]. simpl in *.
  exact (f1 c1, f2 c2).
Defined.

Definition F_choice_prod: ord_functor (prod_cat ord_choiceType ord_choiceType) ord_choiceType.
Proof.
  exists F_choice_prod_obj F_choice_prod_morph.
  - move => [C11 C12] [C21 C22] [s11 s12] [s21 s22] [H1 H2] [x1 x2].
    simpl in *. move: (H1 x1) (H2 x2) => eq1 eq2.
    destruct eq1, eq2. reflexivity.
  - move => [C1 C2]. rewrite /F_choice_prod_morph /=.
    apply: boolp.funext => c. by destruct c.
  - move =>  [C11 C12] [C21 C22] [C31 C32] [f1 f2] [g1 g2].
    simpl in *. apply: boolp.funext => x. by destruct x.
Defined.

(* Definition Simplication { A : Type } : srelation (A -> SProp) := *)
(*   fun (π1 π2 : A -> SProp) => *)
(*      forall (a : A), π1 a -> π2 a. *)

(* Lemma Simplication_refl { A : Type } : Reflexive (@Simplication A). *)
(* Proof. by firstorder. Qed. *)

(* Lemma Simplication_trans { A : Type } : Transitive (@Simplication A). *)
(* Proof. by firstorder. Qed. *)

Definition mono {A : Type} (α : (A -> SProp) -> SProp) : SProp :=
  forall (π1 π2 : A -> SProp),
    (forall a:A, π2 a -> π1 a) -> (* π1 ≤ π2 *)
    ((α π2) -> (α π1)). (* α π1 ≤ α π2 *)


Definition mono_predtrans (A : Type) := {α : (A -> SProp) -> SProp ≫ mono α}.


(* CA: usual ordering on monotonic pred transformes, equality o.w. *)
Definition predtrans_leq {A : Type} :
  (mono_predtrans A) -> mono_predtrans A -> SProp.
Proof.
  move => [α1 mono1] [α2 mono2].
  exact (forall (π : A -> SProp), α2 π -> α1 π).
Defined.


Lemma predtrans_refl {A : Type} : Reflexive (@predtrans_leq A).
Proof. by firstorder. Qed.

Lemma predtrans_trans { A : Type } : Transitive (@predtrans_leq A).
Proof. by firstorder. Qed.

Definition Sorder { A : Type } : ordType.
Proof.
  exists (mono_predtrans A). exists (@predtrans_leq A).
  split.
  - exact predtrans_refl.
  - exact predtrans_trans.
Defined.

(* Definition Sorder { A : Type } :=  *)
(*  Build_PreOrder (@predtrans_leq A) *)
(*                 (@predtrans_refl A)  *)
(*                 (@predtrans_trans A).  *)

(* Definition Cont__P { A : Type } : OrderedMonad := *)
(*     @MonoCont ((A -> SProp) -> SProp) (predtrans_leq) (@Sorder A). *)


Definition M2_obj : Obj (prod_cat ord_choiceType ord_choiceType) -> OrdCat.
Proof.
  move => [[A1 ord1] [A2 ord2]] /=.  exact (@Sorder (A1 * A2)).
Defined.

Definition M2_ret0 (A : Type) : A -> mono_predtrans A.
Proof.
  move => a.
  exists (fun π : A -> SProp => π a).
  move => π1 π2 leq12. firstorder.
Defined.

Definition M2_ret : forall A :  (prod_cat ord_choiceType ord_choiceType),
    OrdCat ⦅ (ord_functor_comp (F_choice_prod) chDiscr) A;
             M2_obj A ⦆.
Proof.
  move => [[A1 ch1] [A2 ch2]] /=.
  exists (M2_ret0 (A1 * A2)).
  move => c1 c2 Heq.
  by destruct Heq.
Defined.

Definition M2_bind0 (A B : Type) (f : A -> mono_predtrans B):
  (mono_predtrans A) -> (mono_predtrans B).
Proof.
  move => [α monoα].
  exists (fun π : B -> SProp => α (fun a => ((Spr1 (f  a)) π))).
  move => π1 π2 leq12 H1.
  apply: (monoα (fun a : A => (f a) ∙1 π1) (fun a : A => (f a) ∙1 π2)).
  move => a. apply: (Spr2 (f a)). apply: leq12.
  assumption.
Defined.

Definition M2_bind : forall A B : (prod_cat ord_choiceType ord_choiceType),
    OrdCat ⦅ (ord_functor_comp (F_choice_prod) chDiscr) A; M2_obj B ⦆ ->
    OrdCat ⦅ M2_obj A; M2_obj B ⦆.
Proof.
  move => [[A1 chA1] [A2 ch_A2]] [[B1 chB1] [B2 ch_B2]] /= [f Hf].
  exists (M2_bind0 (A1 * A2) (B1 * B2) f).
  move => α1 α2 leq12 π /=.
  by apply: leq12.
Defined.

Definition M2 : ord_relativeMonad
                  (ord_functor_comp (F_choice_prod)
                                    chDiscr).
Proof.
  eexists M2_obj M2_ret M2_bind.
  - move =>  [[A1 chA1] [A2 ch_A2]] [[B1 chB1] [B2 ch_B2]] [f1 Hf1] [f2 Hf2] f_leq [α monoα] π /=.
    apply: monoα. move => a. by apply: f_leq.
  - by move => [[A1 chA1] [A2 ch_A2]] /=.
  - by move =>  [[A1 chA1] [A2 ch_A2]] [[B1 chB1] [B2 ch_B2]] [f1 Hf1] /=.
  - by move =>  [[A1 chA1] [A2 ch_A2]] [[B1 chB1] [B2 ch_B2]] [[C1 chC1] [C2 ch_C2]] [f Hf] [g Hg] /=.
Defined.

Definition v0 (C1 C2 : Type) : C1 * C2 -> C1 × C2.
Proof.
  move => [c1 c2]. split; [exact c1 | exact c2].
Defined.

Definition v : forall C : (prod_cat ord_choiceType ord_choiceType),
    OrdCat ⦅ (ord_functor_comp (F_choice_prod) chDiscr) C ;
     (ord_functor_comp (prod_functor choice_incl choice_incl) Jprod) C ⦆.
Proof.
  move => [[C1 ch1] [C2 ch2]] /=.
  eexists (v0 C1 C2).
  move => [x11 x12] [x21 x22] x1_x2.
  destruct x1_x2. by constructor.
Defined.

Definition v_inv0 (C1 C2 : Type) : C1 × C2 -> C1 * C2.
Proof.
  move => [c1 c2]. split; [exact c1 | exact c2].
Defined.

Definition v_inv : forall C : (prod_cat ord_choiceType ord_choiceType),
    OrdCat ⦅ (ord_functor_comp (prod_functor choice_incl choice_incl) Jprod) C;
      (ord_functor_comp (F_choice_prod) chDiscr) C ⦆.
Proof.
  move => [[C1 ch1] [C2 ch2]] /=.
  eexists (v_inv0 C1 C2).
  move => [x11 x12] [x21 x22] x1_x2.
  by destruct x1_x2.
Defined.


Definition ϕ : natIso (ord_functor_comp (F_choice_prod) chDiscr)
                       (ord_functor_comp (prod_functor choice_incl choice_incl)
                                          Jprod).
Proof.
  exists v v_inv.
  - move =>  [[C11 ch11] [C12 ch12]] [[C21 ch21] [C22 ch22]] /= [f1 f2].
    apply: Ssig_eq. rewrite /=.
    apply: boolp.funext. by move => [c1 c2] /=.
  - move => [[C1 ch1] [C2 ch2]] /=.
    by apply: Ssig_eq.
  - move => [[C1 ch1] [C2 ch2]] /=.
    apply: Ssig_eq. rewrite /=.
    apply: boolp.funext. by move => [c1 c2] /=.
Defined.


(* Definition fst_marginal {A1 A2: choiceType} (d1 : {distr A1 / Axioms.R}) *)
(*                                             (d2 : {distr A2 / Axioms.R}) *)
(*                                             (d  : {distr (A1 * A2) / Axioms.R}) : SProp. *)
(* Admitted. (* d1 ≡ λ a1 : A1. Σ_{a2 : A2} d(a1, a2) *) *)


(* Definition snd_marginal {A1 A2: choiceType} (d1 : {distr A1 / Axioms.R}) *)
(*                                             (d2 : {distr A2 / Axioms.R}) *)
(*                                             (d  : {distr (A1 * A2) / Axioms.R}) : SProp. *)
(* Admitted. (* d2 ≡ λ a2 : A2. Σ_{a1 : A1} d(a1, a2) *)  *)

(* Definition marginals {A1 A2: choiceType} (d1 : {distr A1 / Axioms.R}) *)
(*                                          (d2 : {distr A2 / Axioms.R}) *)
(*                                          (d  : {distr (A1 * A2) / Axioms.R}) : SProp :=  *)
(*    sand (fst_marginal d1 d2 d) *)
(*         (snd_marginal d1 d2 d).  *)

(* Definition Uprod_obj : (prod_cat OrdCat OrdCat) -> TypeCatSq. *)
(* Proof. *)
(*   move => [[C1 H1] [C2 H2]]. *)
(*   split.    *)
(*   exact C1. *)
(*   exact C2. *)
(* Defined.  *)

(* Definition Uprod_morph : forall A B : (prod_cat OrdCat OrdCat), *)
(*     (prod_cat OrdCat OrdCat) ⦅ A; B ⦆ -> TypeCatSq ⦅ Uprod_obj A; Uprod_obj B ⦆. *)
(* Proof. *)
(*   move => [[A1 HA1] [A2 HA2]] [[B1 HB1] [B2 HB2]] [[f1 Hf1] [f2 Hf2]].  *)
(*   simpl in *. split.  *)
(*   exact f1. exact f2. *)
(* Defined.  *)

(* Definition Uprod : ord_functor (prod_cat OrdCat OrdCat) TypeCatSq. *)
(* Proof. *)
(*   exists Uprod_obj Uprod_morph. *)
(* Admitted. (*CA: This is not an ord_functor *) *)


(* Definition J12 : ord_functor (prod_cat OrdCat OrdCat) OrdCat := *)
(*   ord_functor_comp Uprod Jprod.  *)

Definition θ0 (A1 A2 : Type) (ch1 : Choice.class_of A1) (ch2 : Choice.class_of A2):
  (SDistr_carrier (Choice.Pack ch1)) × (SDistr_carrier (Choice.Pack ch2)) ->
  mono_predtrans (A1 * A2).
Proof.
  rewrite /SDistr_carrier. move => [d1 d2].
  exists (fun π : A1 * A2 -> SProp => (s∀ d, Prop2SProp (coupling d d1 d2) ->
                                    (s∃ (a1 : A1) (a2 : A2),
                                          (π (a1, a2)) s/\ (d (a1, a2) > 0 ≡ true)))).
  move => π1 π2 leq12 H d coup_d.
  move: (H d coup_d).
  move => [a1 [a2 [Hπ2 Hd]]].
  exists a1, a2. auto.
Defined.

Definition θ : forall A : prod_cat ord_choiceType ord_choiceType,
    OrdCat ⦅ Jprod (SDistr_squ A); M2 A ⦆.
Proof.
  move => [[A1 ch1] [A2 ch2]] /=.
  exists (θ0 A1 A2 ch1 ch2).
  move => [d11 d12] [d21 d22] leq12 π /=.
  inversion leq12. by subst.
Defined.


(* CA:
    1. Do we really need this?
    2. Does this exist already somewhere?
*)
Axiom indefinite_Sdescription : forall {A : Type} (P : A -> SProp),
   Ex P -> Ssig P.

(* Definition kd {A1 A2 B1 B2 : Type} {chA1 : Choice.class_of A1} {chA2 : Choice.class_of A2} *)
(*                                    {chB1 : Choice.class_of B1} {chB2 : Choice.class_of B2} *)
(*               {f1 : TypeCat ⦅ nfst (prod_functor choice_incl choice_incl ⟨ *)
(*                                Choice.Pack chA1, Choice.Pack chA2 ⟩); *)
(*                               nfst (SDistr_squ ⟨Choice.Pack chB1, Choice.Pack chB2 ⟩) ⦆} *)
(*               {f2 :  TypeCat ⦅ nsnd (prod_functor choice_incl choice_incl ⟨ *)
(*                          Choice.Pack chA1, Choice.Pack chA2 ⟩); *)
(*                                nsnd (SDistr_squ ⟨ Choice.Pack chB1, Choice.Pack chB2 ⟩) ⦆} *)
(*               {π : B1 * B2 -> SProp} *)
(*                  (dA : SDistr_carrier (Couplings.F_choice_prod_obj ⟨ Choice.Pack chA1, *)
(*                                                                      Choice.Pack chA2 ⟩)) *)
(*              (integral : forall (a1 : A1) (a2 : A2), *)
(*                          0 < dA (a1, a2) -> *)
(*                          s∃ d : SDistr_carrier (Couplings.F_choice_prod_obj *)
(*                                                   ⟨ Choice.Pack chB1, Choice.Pack chB2 ⟩), *)
(*                              Prop2SProp (coupling d (f1 a1) (f2 a2)) *)
(*                                         s/\ (forall (a3 : B1) (a4 : B2), 0 < d (a3, a4) -> π (a3, a4))) : *)
(*        TypeCat ⦅ choice_incl (F_choice_prod ⟨ Choice.Pack chA1, Choice.Pack chA2 ⟩); *)
(*                  SDistr (F_choice_prod ⟨ Choice.Pack chB1, Choice.Pack chB2 ⟩) ⦆. *)
(* Proof. *)
(*   simpl. move => [a1 a2]. *)
(*   destruct (dA (a1, a2) > 0) eqn: K.  *)
(*   + move/idP: K => K.  *)
(*     move: (integral a1 a2 K) => H. *)
(*     move: (indefinite_Sdescription _ H).  move => [d Hcoup_d_Hforall]. *)
(*     exact d.  *)
(*   + rewrite /SDistr_carrier /F_choice_prod_obj /=. *)
(*     exact dnull.  *)
(* Defined.   *)

(* Lemma kd_coup {A1 A2 B1 B2 : Type} {chA1 : Choice.class_of A1} {chA2 : Choice.class_of A2} *)
(*                                    {chB1 : Choice.class_of B1} {chB2 : Choice.class_of B2} *)
(*                                    {π : B1 * B2 -> SProp} *)
(*        (dA : SDistr_carrier (Couplings.F_choice_prod_obj ⟨ Choice.Pack chA1, *)
(*                                                            Choice.Pack chA2 ⟩)) *)
(*        (f1 : TypeCat ⦅ nfst (prod_functor choice_incl choice_incl ⟨ *)
(*                                Choice.Pack chA1, Choice.Pack chA2 ⟩); *)
(*                        nfst (SDistr_squ ⟨Choice.Pack chB1, Choice.Pack chB2 ⟩) ⦆) *)
(*        (f2 :  TypeCat ⦅ nsnd (prod_functor choice_incl choice_incl ⟨ *)
(*                          Choice.Pack chA1, Choice.Pack chA2 ⟩); *)
(*                    nsnd (SDistr_squ ⟨ Choice.Pack chB1, Choice.Pack chB2 ⟩) ⦆) *)
(*       (integral : forall (a1 : A1) (a2 : A2), *)
(*                   0 < dA (a1, a2) -> *)
(*                   s∃ d : SDistr_carrier (Couplings.F_choice_prod_obj *)
(*                                            ⟨ Choice.Pack chB1, Choice.Pack chB2 ⟩), *)
(*                       Prop2SProp (coupling d (f1 a1) (f2 a2)) *)
(*                                  s/\ (forall (a3 : B1) (a4 : B2), 0 < d (a3, a4) -> π (a3, a4))) : *)
(*   (forall (x1 : A1) (x2 : A2), coupling ((kd dA integral) (x1,x2)) (f1 x1) (f2 x2)). *)
(* Proof. *)
(*   move => a1 a2. *)
(*   destruct (0 < dA (a1, a2)) eqn: K. *)
(*   + rewrite /kd. vm_compute.    *)
(*     have K_true: is_true(0 < dA (a1, a2)) by rewrite K. *)
(*     rewrite K_true.  *)

Axiom NNPP : forall p:Prop, ~ ~ p -> p.

Lemma an_easy_lemma : forall r : R, r < r -> False.
Admitted.


Definition θ_morph : relativeLaxMonadMorphism
                                (* C  = choiceType × choiceType *)
                                (* D1 = OrdCat × OrdCat *)
                                (* D2 = OrdCat *)
                                (* J1 : C → D1, J1 = chDiscr × chDiscr *)
                                (* J2 : C → D2, J2 =  *)
                               Jprod (* J12 : D1 → D2 *)
                               ϕ (* : natIso J2 (J1; J12) *)
                               SDistr_squ (* ord_relativeMonad J1 *)
                               M2 (* ord_relativeMonad J2*).
Proof.
  exists θ.
  - move => [[C1 ch1] [C2 ch2]].
    simpl. rewrite /SubDistr.SDistr_obligation_1 /SDistr_unit.
    unfold "≤". rewrite /= /predtrans_leq /v_inv0 /=.
    move => [c1 c2] π π_x d Scoup_d.
    exists c1, c2.
    split.
    -- assumption.
    -- move: (SProp2Prop_truthMorphism_leftRight _ Scoup_d).
       rewrite PSP_retr => coup_d.
       have dis1 : d(c1, c2) = 1.
       { rewrite <- coupling_vs_ret in coup_d.
         rewrite coup_d. rewrite /SDistr_unit /=.
         rewrite dunit1E. admit. }
       rewrite dis1. admit.
  - move => [[A1 chA1] [A2 chA2]] [[B1 chB1] [B2 chB2]] [f1 f2] [c1 c2] /=.
    unfold "≤". rewrite /= /predtrans_leq /v_inv0 /=. simpl in *.
    move => π H d coup_d.
    Abort.
    (* CA: not sure this is a monad morphism *)