Set Warnings "-notation-overridden,-ambiguous-paths".
From mathcomp Require Import all_ssreflect all_algebra reals distr realsum
  fingroup.fingroup solvable.cyclic prime ssrnat ssreflect ssrfun ssrbool
  ssrnum eqtype choice seq.
Set Warnings "notation-overridden,ambiguous-paths".

Require Import List.
Set Warnings "-notation-overridden".
From Jasmin Require Import expr.
Set Warnings "notation-overridden".
From Jasmin Require Import x86_instr_decl x86_extra.
From JasminSSProve Require Import jasmin_translate.
From Crypt Require Import Prelude Package.

Import ListNotations.
Local Open Scope string.




Definition ssprove_jasmin_prog : uprog.
Proof.
  refine {| p_funcs :=
 [ ( (* incr *) xI xH,
     {| f_info := xO (xO xH)
      ; f_tyin := [sint]
      ; f_params :=
          [{| v_var := {| vtype := sint
                        ; vname := "n.152"  |}
            ; v_info := dummy_var_info |}]
      ; f_body :=
          [ MkI InstrInfo.witness
             (Cassgn
                (Lvar
                   {| v_var := {| vtype := sint
                                ; vname := "m.153"  |}
                    ; v_info := dummy_var_info |})
                AT_inline (sint)
                ((Papp2 (Olsl Op_int)
                    (Pvar
                       {| gv := {| v_var :=
                                     {| vtype := sint
                                      ; vname := "n.152"  |}
                                 ; v_info := dummy_var_info |} ; gs := Slocal |})
                    (Pconst (Zpos (xI (xO (xO (xO (xO (xO xH))))))))))) ]
      ; f_tyout := [sint]
      ; f_res :=
          [{| v_var := {| vtype := sint
                        ; vname := "m.153"  |}
            ; v_info := dummy_var_info |}]
      ; f_extra := tt
      ; |} )
 ; ( (* f *) xH,
     {| f_info := xO xH
      ; f_tyin := []
      ; f_params := []
      ; f_body :=
          [ MkI InstrInfo.witness
             (Ccall InlineFun
                [Lvar
                   {| v_var := {| vtype := sint
                                ; vname := "x.151"  |}
                    ; v_info := dummy_var_info |}]
                (xI xH) [(Pconst (Z0))]);
            MkI InstrInfo.witness
             (Cassgn
                (Lvar
                   {| v_var := {| vtype := (sword U64)
                                ; vname := "y.150"  |}
                    ; v_info := dummy_var_info |})
                AT_none ((sword U64))
                ((Papp1 (Oword_of_int U64)
                    (Pvar
                       {| gv := {| v_var :=
                                     {| vtype := sint
                                      ; vname := "x.151"  |}
                                 ; v_info := dummy_var_info |} ; gs := Slocal |})))) ]
      ; f_tyout := [(sword U64)]
      ; f_res :=
          [{| v_var := {| vtype := (sword U64)
                        ; vname := "y.150"  |}
            ; v_info := dummy_var_info |}]
      ; f_extra := tt
      ; |} ) ] ;
  p_globs := [] ;
  p_extra := tt |}.
Defined.