Require Import VST.concurrency.main_definitions.
Require Import VST.concurrency.compiler.sequential_compiler_correct.
Require Import VST.concurrency.compiler.concurrent_compiler_simulation_definitions.


Module MainTheorem_statement
       (CC_correct: CompCert_correctness)
       (Args: ThreadSimulationArguments).
  Import CC_correct Args.

  (* Temporary lemma for exposition. Deleete until ["Delete until here"]*)
  Import Clight.
  
  (* We want to prove something like this. Maybe with extra assumptions, 
     or (probably) the convers. In the end we want to unify the two predicates. *)
  Lemma entry_point_problem:
    forall src_m src_cpm,
      Clight.entry_point
        (Clight.globalenv C_program) src_m src_cpm (main_ptr C_program) nil ->
      CSL_init_setup C_program src_m src_cpm.
  Proof.
    intros.
    inversion H; subst.
    econstructor; eauto.
    - (* The two ways of getting an initial state:
         LHS -  Clight_init_state, how the CSL proof defines initial states
         RHS -  Clight.entry_point our new way of defining initial states 
                (entry points)
       *)
      unfold Clight_init_state; simpl.
      admit. (*The intialistaions don't match*)
    - admit. (* We need some assumption about src_m *)
    - admit. (* b0 comees out of nowhere. *)
  Admitted.
      

      (* End of temporary exposition *)
  Goal True.
    idtac "Delete until here".
  
  Definition top2bottom_safety: Prop:=
    (* C program is proven to be safe in CSL*)
      CSL_correct C_program ->

      (* C program compiles to some assembly program*)
      forall (asm_prog:Asm.program),
      CompCert_compiler C_program = Some asm_prog ->
      
      forall (src_m:Memory.mem) (src_cpm:Clight.state),
        (* Initial State for CSL *)
        CSL_init_setup C_program src_m src_cpm ->
        
        (*Correct entry point Clight (There is inconsistencies with CSL_init_Setup)*)
        (* TODO: fix initial state inconsistenciees and unify. *)
        Clight.entry_point (Clight.globalenv C_program) src_m src_cpm (main_ptr C_program) nil ->
        
        (* ASM memory good. *)
        forall (limited_builtins:Asm_core.safe_genv x86_context.X86Context.the_ge),
        asm_prog_well_formed asm_prog limited_builtins ->
        
        forall U, exists tgt_m0 tgt_m tgt_cpm,
            (* inital asm machine *)
            barebones_init_machine
              asm_prog limited_builtins
              tgt_m0 tgt_cpm tgt_m (main_ptr C_program) nil /\

            (*it's spinlock safe: well synchronized and safe *)
            spinlock_safe U tgt_cpm tgt_m.
End MainTheorem_statement.

Require Import VST.concurrency.main_proofs.
Require Import VST.concurrency.lib.tactics.

Module MainTheorem_Proof
       (CC_correct: CompCert_correctness)
       (Args: ThreadSimulationArguments).
  Import CC_correct Args.
  Module Theorem_statement:=MainTheorem_statement CC_correct Args.
  Module Theorem_proofs:=Main CC_correct Args.
  Import Theorem_statement Theorem_proofs.

  Hint Unfold top2bottom_safety.
  Hint Transparent top2bottom_safety.
  Theorem top2bottom_safety_proof: top2bottom_safety.
  Proof. (autounfold; eapply main_safety_clean). Qed.
  
End MainTheorem_Proof.

(* Test an instantiation of Main theorem. *)
Module CC_correct: CompCert_correctness.
  Axiom CompCert_compiler : Clight.program -> option Asm.program.
  Axiom simpl_clight_semantic_preservation :
    forall (p : Clight.program) (tp : Asm.program),
      CompCert_compiler p = Some tp ->
      ExposedSimulations.fsim_properties_inj_relaxed (Clight.semantics2 p) (Asm.semantics tp)
                                             Clight.get_mem Asm.get_mem.

End CC_correct.

Module ProgramArgs: ThreadSimulationArguments.

  Parameter C_program: Clight.program.
  Parameter Asm_program: Asm.program.
  Definition Asm_g := (@x86_context.X86Context.the_ge Asm_program).
  Parameter Asm_genv_safe: Asm_core.safe_genv Asm_g.
    
End ProgramArgs.


Module Test_Main:= (MainTheorem_Proof CC_correct ProgramArgs).
Import Test_Main.

Check Theorem_statement.top2bottom_safety.
Check top2bottom_safety_proof.
Print Assumptions top2bottom_safety_proof.
