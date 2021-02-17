(** Asymmetric encryption schemes

  In the stateful and probabilistic setting.
  This module defines:

    1. CPA_security    "security under chosen plaintext attacks"
    2. CPA_rnd_cipher  "cipher looks random"
    3. OT_secrecy      "one-time secrecy"
    4. OT_rnd_cipher   "cipher looks random when the key is used only once"

    4. -> 3. -> 2. -> 1

*)

From Relational Require Import
     OrderEnrichedCategory
     GenericRulesSimple.

Set Warnings "-notation-overridden,-ambiguous-paths".
From mathcomp Require Import
     all_ssreflect
     all_algebra
     reals
     distr
     realsum.
Set Warnings "notation-overridden,ambiguous-paths".

From Crypt Require Import
     Axioms
     ChoiceAsOrd
     SubDistr
     Couplings
     UniformDistrLemmas
     FreeProbProg
     Theta_dens
     RulesStateProb
     UniformStateProb.
From Crypt Require Import
     pkg_core_definition
     pkg_chUniverse
     pkg_composition
     pkg_notation
     pkg_rhl
     Package
     Prelude.


From Coq Require Import Utf8.
Set Warnings "-ambiguous-paths,-notation-overridden,-notation-incompatible-format".
From mathcomp Require Import ssrnat ssreflect ssrfun ssrbool ssrnum eqtype choice seq.
Set Warnings "ambiguous-paths,notation-overridden,notation-incompatible-format".
From extructures Require Import ord fset fmap.

Set Bullet Behavior "Strict Subproofs".
Set Default Goal Selector "!".
Set Primitive Projections.

Import Num.Def.
Import Num.Theory.
Import mc_1_10.Num.Theory.

Local Open Scope ring_scope.


(* ASymmetric Schemes *)
Module Type AsymmetricSchemeParams.

  Parameter SecurityParameter : choiceType.
  Parameters Plain Cipher PubKey SecKey : finType.
  Parameter plain0 : Plain.
  Parameter cipher0 : Cipher.
  Parameter pub0 : PubKey.
  Parameter sec0 : SecKey.

  (*Rem.: If I don't put these here I get some troubles later... *)

  Parameter probE : Type → Type.
  Parameter rel_choiceTypes : Type.
  Parameter chEmb : rel_choiceTypes → choiceType.
  Parameter prob_handler : forall T : choiceType, probE T → SDistr T.
  Parameter Hch : forall r : rel_choiceTypes, chEmb r.

End AsymmetricSchemeParams.

Module ARules (Aparam : AsymmetricSchemeParams).

  Export Aparam.

  (*: Uniform distributions over Plain, Cipher, Key and bool *)
  Variant Index :=
  | i_plain  : Index
  | i_cipher : Index
  | i_pk     : Index
  | i_sk     : Index
  | i_bool   : Index.


  Module UParam <: UniformParameters.

    Definition Index : Type := Index.

    Definition i0 : Index := i_plain.

    Definition fin_family : Index → finType :=
      λ i,
        match i with
        | i_plain   => Plain
        | i_cipher  => Cipher
        | i_pk      => PubKey
        | i_sk      => SecKey
        | i_bool    => bool_finType
        end.

    Definition F_w0 : ∀ (i : Index), (fin_family i).
    Proof.
      case; rewrite /fin_family;
      [exact plain0| exact cipher0 | exact pub0 | exact sec0 | exact false].
    Defined.

  End UParam.

  Module genparam <: RulesParam.

    Definition probE : Type → Type := probE.
    Definition rel_choiceTypes : Type := rel_choiceTypes.
    Definition chEmb : rel_choiceTypes → choiceType := chEmb.
    Definition prob_handler : forall T : choiceType, probE T → SDistr T :=
      prob_handler.
    Definition Hch : ∀ (r : rel_choiceTypes), chEmb r := Hch.

  End genparam.

  Module MyARulesUniform := DerivedRulesUniform genparam UParam.
  Export MyARulesUniform.

End ARules.

(** algorithms for Key Generation, Encryption and Decryption  **)
Module Type AsymmetricSchemeAlgorithms (π : AsymmetricSchemeParams).

  Import π.
  Module asym_rules := (ARules π).
  Export asym_rules.
  Import asym_rules.MyARulesUniform.

  Module MyPackage := Package_Make myparamU.
  Export MyPackage.
  Import PackageNotation.
  Local Open Scope package_scope.

  Definition counter_loc : Location := ('nat ; 0%N).
  Definition pk_loc : Location := ('nat ; 1%N).
  Definition sk_loc : Location := ('nat ; 2%N).
  Definition m_loc  : Location := ('nat ; 3%N).
  Definition c_loc  : Location := ('nat ; 4%N).

  Definition kg_id : nat := 5.
  Definition enc_id : nat := 6.
  Definition dec_id : nat := 7.
  Definition challenge_id : nat := 8. (*challenge for LR *)
  Definition challenge_id' : nat := 9. (*challenge for real rnd *)


  (* Definition rel_loc : {fset Location} := [fset counter_loc]. *)
  (* Rem.: ; kg_loc ; enc_loc ; dec_loc ; challenge_loc ; pk_loc; sk_loc]. *)

  Instance Plain_len_pos : Positive #|Plain|.
  Proof.
    apply /card_gt0P. by exists plain0.
  Qed.

  Instance Cipher_len_pos : Positive #|Cipher|.
  Proof.
    apply /card_gt0P. by exists cipher0.
  Qed.

  Instance PubKey_len_pos : Positive #|PubKey|.
  Proof.
    apply /card_gt0P. by exists pub0.
  Defined.

  Instance SecKey_len_pos : Positive #|SecKey|.
  Proof.
    apply /card_gt0P. by exists sec0.
  Qed.

  Notation " 'chSecurityParameter' " :=
    (chNat) (in custom pack_type at level 2).
  Notation " 'chPlain' " :=
    ('fin #|Plain|)
    (in custom pack_type at level 2).
  Notation " 'chCipher' " :=
    ('fin #|Cipher|)
    (in custom pack_type at level 2).
  Notation " 'chPubKey' " :=
    ('fin #|PubKey|)
    (in custom pack_type at level 2).
  Notation " 'chSecKey' " :=
    ('fin #|SecKey|)
    (in custom pack_type at level 2).

  Parameter c2ch : Cipher → 'fin #|Cipher|.
  Parameter ch2c : 'fin #|Cipher| → Cipher.
  (* *)
  Parameter pk2ch : PubKey → 'fin #|PubKey|.
  Parameter ch2pk : 'fin #|PubKey| → PubKey.
  (* *)
  Parameter sk2ch : SecKey → 'fin #|SecKey|.
  Parameter ch2sk : 'fin #|SecKey| → SecKey.
  (* *)
  Parameter m2ch : Plain → 'fin #|Plain|.
  Parameter ch2m : 'fin #|Plain| → Plain.
  (* *)

  (*** TODO ****)
  (* UPDATE BELOW *)
  (* Indeed, we can already see [program] here which feels wrong with the new
    approach.
  *)

  (* Key Generation *)
  Parameter KeyGen :
    ∀ {L : {fset Location}}, program L fset0 ('fin #|PubKey| × 'fin #|SecKey|).

  (* Encryption algorithm *)
  Parameter Enc :
    ∀ {L : {fset Location}} (pk : 'fin #|PubKey|) (m : 'fin #|Plain|),
      program L fset0 ('fin #|Cipher|).

  (* Decryption algorithm *)
  Parameter Dec_open :
    ∀ {L : {fset Location}} (sk : 'fin #|SecKey|) (c : 'fin #|Cipher|),
      program L fset0 ('fin #|Plain|).

End AsymmetricSchemeAlgorithms.

(* A Module for Asymmetric Encryption Schemes, inspired to Joy of Crypto *)
Module AsymmetricScheme (π : AsymmetricSchemeParams)
                        (Alg : AsymmetricSchemeAlgorithms π).

  Import Alg.
  Import PackageNotation.

  Definition U (i : Index) :
    {rchT : myparamU.rel_choiceTypes & myparamU.probE (myparamU.chEmb rchT)} :=
    (existT (λ rchT : myparamU.rel_choiceTypes, myparamU.probE (myparamU.chEmb rchT))
            (inl (inl i)) (inl (Uni_W i))).

  Local Open Scope package_scope.

   (* Define what it means for an asymmetric encryption scheme to be: *)
   (**   *SECURE AGAINST CHOSEN-PLAINTEXT ATTACKS **)

  Definition L_locs : { fset Location } := fset [:: pk_loc ; sk_loc ].

  (* TODO INVESTIGATE:
    If I put _ instead of L_locs, the following loops.
    So probably some problem with how I try to infer \in?
  *)

  Definition L_pk_cpa_L :
    package
      L_locs
      [interface]
      [interface val #[challenge_id] : chPlain × chPlain → chCipher ] :=
    [package
      def #[challenge_id] ( mL_mR : chPlain × chPlain ) : chCipher
      {
        '(pk, sk) ← KeyGen ;;
        put pk_loc := pk ;;
        put sk_loc := sk ;;
        c ← Enc pk (fst mL_mR) ;;
        ret c
      }
    ].

  Definition L_pk_cpa_R :
    package
      L_locs
      [interface]
      [interface val #[challenge_id] : chPlain × chPlain → chCipher ] :=
    [package
      def #[challenge_id] ( mL_mR : chPlain × chPlain ) : chCipher
      {
        '(pk, sk) ← KeyGen ;;
        put pk_loc := pk ;;
        put sk_loc := sk ;;
        c ← Enc pk (snd mL_mR) ;;
        ret c
      }
    ].

  (* TODO Use {locpackage} here or above? *)
  Definition cpa_L_vs_R : GamePair [interface val #[challenge_id] : chPlain × chPlain → chCipher] :=
    λ b, if b then {locpackage L_pk_cpa_L} else {locpackage L_pk_cpa_R}.

  (** [The Joy of Cryptography] Definition 15.1

    A public-key encryption scheme is secure against chosen-plaintext attacks
    when the following holds.
  *)

  Definition CPA_security : Prop :=
    ∀ A,
      adv_forp A cpa_L_vs_R →
      Advantage cpa_L_vs_R A = 0.

  (* Define what it means for an asymmetric encryption scheme to: *)
  (**  *HAVE PSEUDORND CIPHERTEXT IN PRESENCE OF CHOSEN PLAINTEXT ATTACKS **)

  Definition L_pk_cpa_real :
    package L_locs
      [interface]
      [interface val #[challenge_id] : chPlain → chCipher ] :=
    [package
      def #[challenge_id] (m : chPlain) : chCipher
      {
        '(pk, sk) ← KeyGen ;;
        put pk_loc := pk ;;
        put sk_loc := sk ;;
        c ← Enc pk m ;;
        ret c
      }
    ].

  Definition L_pk_cpa_rand :
    package L_locs
      [interface]
      [interface val #[challenge_id] : chPlain → chCipher ] :=
    [package
      def #[challenge_id] (m : chPlain) : chCipher
      {
        '(pk, sk) ← KeyGen ;;
         put pk_loc := pk ;;
         put sk_loc := sk ;;
         c ← sample U i_cipher ;;
         ret (c2ch c)
      }
    ].

  Definition cpa_real_vs_rand :
    GamePair [interface val #[challenge_id] : chPlain → chCipher] :=
    λ b, if b then {locpackage L_pk_cpa_real } else {locpackage L_pk_cpa_rand }.

  (** [The Joy of Cryptography] Definition 15.2

    A public-key encryption scheme has pseudornd ciphertext against
    chosen-plaintext attacks when the following holds.
  *)

  Definition CPA_rnd_cipher : Prop :=
    ∀ A,
      adv_forp A cpa_real_vs_rand →
      Advantage cpa_real_vs_rand A = 0.

  (* Define what it means for an asymmetric encryption scheme to have: *)
  (**   *ONE-TIME SECRECY **)

  Definition L_locs_counter := fset [:: counter_loc ; pk_loc ; sk_loc].

  Definition L_pk_ots_L :
    package L_locs_counter
      [interface]
      [interface val #[challenge_id] : chPlain × chPlain → 'option chCipher ] :=
    [package
      def #[challenge_id] ( mL_mR : chPlain × chPlain ) : 'option chCipher
      {
        count ← get counter_loc ;;
        put counter_loc := (count + 1)%N;;
        if ((count == 0)%N) then
          '(pk, sk) ← KeyGen ;;
          put pk_loc := pk ;;
          put sk_loc := sk ;;
          c ← Enc pk (fst mL_mR) ;;
          ret (some c)
        else ret None
      }
    ].

  Definition L_pk_ots_R :
    package L_locs_counter
      [interface]
      [interface val #[challenge_id] : chPlain × chPlain → 'option chCipher ] :=
    [package
      def #[challenge_id] ( mL_mR :  chPlain × chPlain ) : 'option chCipher
      {
        count ← get counter_loc ;;
        put counter_loc := (count + 1)%N;;
        if ((count == 0)%N) then
          '(pk, sk) ← KeyGen ;;
          put pk_loc := pk ;;
          put sk_loc := sk ;;
          c ← Enc pk (snd mL_mR) ;;
          ret (some c)
        else ret None
      }
    ].

  Definition ots_L_vs_R :
    GamePair [interface
      val #[challenge_id] :chPlain × chPlain → 'option chCipher
    ] :=
    λ b, if b then {locpackage L_pk_ots_L } else {locpackage L_pk_ots_R }.

  (** [The Joy of Cryptography] Definition 15.4

    A public-key encryption scheme is secure against chosen-plaintext attacks
    when the following holds.
  *)

  Definition OT_secrecy : Prop :=
    ∀ A,
      adv_forp A ots_L_vs_R →
      Advantage ots_L_vs_R A = 0.

  (*  *)

  Definition L_pk_ots_real :
    package L_locs_counter
      [interface]
      [interface val #[challenge_id'] : chPlain → 'option chCipher ] :=
    [package
      def #[challenge_id'] ( m : chPlain  ) : 'option chCipher
      {
        count ← get counter_loc ;;
        put counter_loc := (count + 1)%N;;
        if ((count == 0)%N) then
          '(pk, sk) ← KeyGen ;;
          put pk_loc := pk ;;
          put sk_loc := sk ;;
          c ← Enc pk m ;;
          ret (some c)
        else ret None
      }
    ].

  Definition L_pk_ots_rnd :
    package L_locs_counter
      [interface]
      [interface val #[challenge_id'] : chPlain → 'option chCipher ] :=
    [package
      def #[challenge_id'] ( m : chPlain ) : 'option chCipher
      {
        count ← get counter_loc ;;
        put counter_loc := (count + 1)%N;;
        if ((count == 0)%N) then
          '(pk, sk) ← KeyGen ;;
          put pk_loc := pk ;;
          put sk_loc := sk ;;
          c ← sample U i_cipher ;;
          ret (some (c2ch c))
        else ret None
      }
    ].

  Definition ots_real_vs_rnd :
    GamePair [interface val #[challenge_id'] : chPlain → 'option chCipher] :=
    λ b, if b then {locpackage L_pk_ots_real } else {locpackage L_pk_ots_rnd }.

  Definition OT_rnd_cipher : Prop :=
    ∀ A,
      adv_forp A ots_real_vs_rnd →
      Advantage ots_real_vs_rnd A = 0.

End AsymmetricScheme.
