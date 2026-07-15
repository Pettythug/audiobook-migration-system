# TASK-[ID]: [Task Title]

> **For Human Readers:** [Provide a brief, human-readable summary of what this task accomplishes and why.]

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: [SINGLE_FILE_FEATURE | MULTI_FILE_Refactoring | ARCHITECTURE_CHANGE | MAINTENANCE]
    - REQUIRED_MODEL_TIER: [LOW_TIER | MEDIUM_TIER | HIGH_TIER]
    - ALIGNMENT_CHECK: IF(Active_Model NOT IN [List Exact Approved Models Here]) THEN(HALT -> OUTPUT: "Model Alignment Error: Please switch my model to [List Exact Approved Models Here] to proceed.")
  </GATEKEEPER>
  
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: [Sandbox_Developer | QA_Engineer]
    - SYSTEM_OVERRIDE: [List any temporary ALLOW/DENY access overrides needed for this task, e.g., TEMPORARY_ALLOW(Write: "/src/*")]
  </ROLE_DEFINITION>
  
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-[ID]`
  </ENVIRONMENT_SETUP>
  
  <OBJECTIVE>
    1. [Clear definition of step 1 goal]
    2. [Clear definition of step 2 goal]
  </OBJECTIVE>
  
  <RESOURCES>
    - [Path to File 1]
    - [Path to File 2]
  </RESOURCES>
  
  <SEQUENCE>
    1. PLAN: Write your execution plan to `docs/jira_tasks/plans/PLAN-[ID].md` and commit it.
    
    2. IMPLEMENTATION:
       a. [Specific instruction 1]
       b. ABSOLUTE CONSTRAINT: [e.g., STRICTLY_DENY(Remove-Item). Relocate items to Holding Cell.]
    
    3. TESTING/VERIFICATION:
       a. [Write test scripts or validation logic]
       b. [Execute mock tests]
    
    4. AUDIT: Generate `/audit_log_[ID].md` detailing the test success and the terminal outputs of all live runs.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
