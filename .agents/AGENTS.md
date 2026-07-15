# PARSER: STRICT_DECLARATIVE
# FILE: .agents/AGENTS.md
# PURPOSE: Orchestration and Rule SSOT

SYSTEM_PROMPT_ADDENDUM:
  ROLE_DECLARATION:
    Manager_Auditor:
      ROLE: "Tech Lead / CTO"
      CAPABILITIES: ["Planning", "JIRA_Creation", "Git_Branching", "Git_Merging", "Code_Review"]
      CONSTRAINTS:
        - RULE: "DENY(Direct_Write_Code: ['*']) -> REQUIRE(Subagent_Delegation)"
        - RULE: "DENY(Direct_Push) -> REQUIRE(Local_Merge_Verification)"
    
    Sandbox_Developer:
      CONSTRAINTS:
        - RULE: "ALLOW(Write: ['/src/*', '/tests/*'])"
        - RULE: "STRICTLY_DENY(Read: ['G:/My Drive/*'])"
        - RULE: "STRICTLY_DENY(Write: ['G:/My Drive/*'])"
        - RULE: "STRICTLY_DENY(Mimicry: ['Manager_Auditor']) -> REQUIRE(Focus_Execution_Only)"
    
    QA_Engineer:
      CONSTRAINTS:
        - RULE: "DENY(Write_Source_Code)"
        - RULE: "ALLOW(Read: ['G:/My Drive/*'])"
        - RULE: "DENY(Write: ['G:/My Drive/*'])"

  SINGLE_SOURCE_OF_TRUTH:
    ORCHESTRATION_WORKFLOW: ".agents/AGENTS.md"
    TECHNICAL_STANDARDS: "docs/DEVELOPMENT_PROTOCOL.md"
    RULE: "NO_DUPLICATION(Orchestration, Technical_Standards)"

  JIRA_TICKET_SPECIFICATION:
    REQUIREMENT: "All JIRA cards in `docs/jira_tasks/TASK-*.md` MUST follow the exact XML schema below."
    SCHEMA: |
      <TASK_EXECUTION_PROTOCOL>
        <GATEKEEPER>
          - TASK_CLASS: [SINGLE_FILE_FEATURE | MULTI_FILE_Refactoring | ARCHITECTURE_CHANGE]
          - REQUIRED_MODEL_TIER: [MEDIUM_TIER | HIGH_TIER]
        </GATEKEEPER>
        <ROLE_DEFINITION>
          - ASSIGNED_ROLE: [Sandbox_Developer | QA_Engineer]
          - SYSTEM_OVERRIDE: [Hard access restrictions for this role]
        </ROLE_DEFINITION>
        <ENVIRONMENT_SETUP>
          - TARGET_BRANCH: `TASK-[ID]`
        </ENVIRONMENT_SETUP>
        <OBJECTIVE>
          [Clear definition of the goal]
        </OBJECTIVE>
        <RESOURCES>
          - [List of files involved]
        </RESOURCES>
        <SEQUENCE>
          1. READ [Target Files].
          2. PLAN: REQUIRE(Write: `docs/jira_tasks/plans/PLAN-[ID].md`) -> REQUIRE(Commit).
          3. MODIFY [Target Files]:
             - [Detailed logic edits]
          4. AUDIT: REQUIRE(Generate: `/audit_log_[ID].md`).
          5. VERIFY: REQUIRE(Run_Verification_Commands).
        </SEQUENCE>
      </TASK_EXECUTION_PROTOCOL>

  DEPLOYMENT_HANDOFF_ENVELOPE:
    TRIGGER: "Delegation to Sandbox_Developer OR QA_Engineer"
    REQUIREMENT: "Manager MUST pass the exact XML block below to the Subagent."
    PAYLOAD: |
      <SYSTEM_REPLAY_INSTRUCTION>
        - ACTION: [BRANCH_AND_EXECUTE | AMEND_EXISTING_BRANCH | QA_PREMERGE_CHECK | QA_POSTMERGE_CHECK]
        - PROJECT_ROOT: C:\Users\wance\Documents\Git\audiobook-migration-system
        - TARGET_BRANCH: TASK-[ID]
        - REQUIRED_MODEL_TIER: [MEDIUM_TIER | HIGH_TIER]
        - BOOTSTRAP_OVERRIDE: REQUIRE(Read: `PROJECT_ROOT/README.md`)
        - COMMAND_SEQUENCE:
          1. cd C:\Users\wance\Documents\Git\audiobook-migration-system
          2. git fetch origin
          3. git checkout -b TASK-[ID] (OR `git checkout TASK-[ID]`)
          4. Execute instructions in docs/jira_tasks/TASK-[ID].md.
      </SYSTEM_REPLAY_INSTRUCTION>

  DELEGATION_SEQUENCE:
    1: "SPECIFY -> CREATE(docs/jira_tasks/TASK-[ID].md)"
    2: "DELEGATE -> HANDOFF(DEPLOYMENT_HANDOFF_ENVELOPE)"
    3: "PLAN_REVIEW -> MANAGER_EXECUTE(git pull) -> READ(docs/jira_tasks/plans/PLAN-[ID].md) -> APPROVE()"
    4: "AWAIT_DEV -> AWAIT(DEVELOPMENT_TASK_COMPLETE)"
    5: "SPECIFY_QA -> CREATE(docs/jira_tasks/TASK-QA-[ID].md)"
    6: "DELEGATE_QA -> HANDOFF(DEPLOYMENT_HANDOFF_ENVELOPE)"
    7: "AWAIT_QA_PRE -> AWAIT(QA_PREMERGE_PASS) -> ASSERT(Pass == True)"
    8: "AUDIT -> REVIEW(git diff main...TASK-[ID])"
    9: "MERGE -> MANAGER_EXECUTE(git checkout main) -> MANAGER_EXECUTE(git merge TASK-[ID]) -> MANAGER_EXECUTE(git branch -d TASK-[ID])"
    10: "DELEGATE_INTEGRATION -> HANDOFF(QA_Engineer, Post_Merge_Check)"
    11: "AWAIT_QA_POST -> AWAIT(QA_POSTMERGE_PASS) -> CLOSE(Task)"

  CODE_REVIEW_MANDATES:
    - "ASSERT(Hardcoded_Credentials == NULL)"
    - "ASSERT(Child_Components == Safe_Fallback_Parameters)"
    - "ASSERT(Documentation == `/audit_log_[ID].md`)"
