import { describe, expect, test } from "bun:test";
import {
  checkCommandMutation,
  isMcpMutationTool,
  isMutatingCommand,
  maskStringLiterals,
  splitPipelineStages,
} from "../extensions/plan-build";

describe("plan-build: maskStringLiterals", () => {
  test("masks double-quoted strings", () => {
    expect(maskStringLiterals('echo "hello world"')).toBe('echo "__STR__"');
  });

  test("masks single-quoted strings", () => {
    expect(maskStringLiterals("echo 'hello world'")).toBe("echo '__STR__'");
  });

  test("handles escaped quotes inside double quotes", () => {
    expect(maskStringLiterals('echo "hello \\"world\\""')).toBe('echo "__STR__"');
  });

  test("preserves outer code while masking inner comparisons", () => {
    const cmd = 'python3 -c "if x > 5: print(x)"';
    expect(maskStringLiterals(cmd)).toBe('python3 -c "__STR__"');
  });
});

describe("plan-build: splitPipelineStages", () => {
  test("splits pipelines with |", () => {
    const stages = splitPipelineStages("cat file.txt | grep foo | wc -l");
    expect(stages).toEqual(["cat file.txt", "grep foo", "wc -l"]);
  });

  test("does not split on | inside quotes", () => {
    const stages = splitPipelineStages('python3 -c "a = x | y" | grep foo');
    expect(stages).toEqual(['python3 -c "a = x | y"', "grep foo"]);
  });

  test("splits compound operators &&, ||, ;", () => {
    const stages = splitPipelineStages("echo 1 && echo 2 || echo 3; echo 4");
    expect(stages).toEqual(["echo 1", "echo 2", "echo 3", "echo 4"]);
  });
});

describe("plan-build: computational inspection (ALLOWED in plan mode)", () => {
  test("allows python3 -c with comparison operators (> and >=)", () => {
    expect(isMutatingCommand('python3 -c "if count > 5 and x >= 2: print(count)"')).toBe(false);
  });

  test("allows python3 with variable names that look like unix tools", () => {
    expect(isMutatingCommand('python3 -c "cp = 10; rm = [1, 2]; print(cp, rm)"')).toBe(false);
  });

  test("allows analytical BigQuery SELECT queries with > filters", () => {
    const query = 'bq query "SELECT id, count FROM my_table WHERE created_at > \'2025-01-01\'"';
    expect(isMutatingCommand(query)).toBe(false);
  });

  test("allows git read-only plumbing & porcelain (merge-base, merge-tree, diff, status, log)", () => {
    expect(isMutatingCommand("git merge-base origin/main HEAD")).toBe(false);
    expect(isMutatingCommand("git merge-tree origin/main HEAD")).toBe(false);
    expect(isMutatingCommand("git status --short")).toBe(false);
    expect(isMutatingCommand("git diff HEAD~1")).toBe(false);
    expect(isMutatingCommand("git log -n 5 --oneline")).toBe(false);
    expect(isMutatingCommand("git rev-parse HEAD")).toBe(false);
    expect(isMutatingCommand("git branch --list")).toBe(false);
  });

  test("allows cloud inspection verbs (list, get, describe, show)", () => {
    expect(isMutatingCommand("aws s3 ls")).toBe(false);
    expect(isMutatingCommand("aws ec2 describe-instances")).toBe(false);
    expect(isMutatingCommand("gcloud compute instances list")).toBe(false);
    expect(isMutatingCommand("gcloud compute instances describe my-vm")).toBe(false);
    expect(isMutatingCommand("az vm list")).toBe(false);
    expect(isMutatingCommand("kubectl get pods -A")).toBe(false);
    expect(isMutatingCommand("kubectl describe pod my-pod")).toBe(false);
    expect(isMutatingCommand("gh pr view 123")).toBe(false);
    expect(isMutatingCommand("gh issue list")).toBe(false);
  });

  test("allows cloud operations with explicit dry-run flags", () => {
    expect(isMutatingCommand("kubectl apply -f manifest.yaml --dry-run=client")).toBe(false);
    expect(isMutatingCommand("bq query --dry_run 'UPDATE table SET x = 1'")).toBe(false);
  });

  test("allows suppressing output to /dev/null and fd redirects (2>&1)", () => {
    expect(isMutatingCommand("python3 -c 'print(1)' > /dev/null 2>&1")).toBe(false);
    expect(isMutatingCommand("git diff > /dev/null")).toBe(false);
  });

  test("allows read-only HTTP GET requests without file output flags", () => {
    expect(isMutatingCommand("curl https://api.example.com/data")).toBe(false);
    expect(isMutatingCommand("curl -X GET https://api.example.com/data")).toBe(false);
  });
});

describe("plan-build: state mutations (BLOCKED in plan mode)", () => {
  test("blocks unquoted shell file redirections", () => {
    expect(isMutatingCommand("echo 'data' > output.txt")).toBe(true);
    expect(isMutatingCommand("cat file.txt >> /tmp/appended.log")).toBe(true);
    expect(isMutatingCommand("echo 'data' &> output.txt")).toBe(true);
    expect(isMutatingCommand("cat file.txt &>> /tmp/appended.log")).toBe(true);
  });

  test("blocks POSIX file mutation commands", () => {
    expect(isMutatingCommand("rm -rf src/")).toBe(true);
    expect(isMutatingCommand("mv old.txt new.txt")).toBe(true);
    expect(isMutatingCommand("cp a.txt b.txt")).toBe(true);
    expect(isMutatingCommand("mkdir -p new_dir")).toBe(true);
    expect(isMutatingCommand("chmod +x script.sh")).toBe(true);
    expect(isMutatingCommand("touch new_file.txt")).toBe(true);
  });

  test("blocks Git mutations", () => {
    expect(isMutatingCommand("git commit -m 'feat'")).toBe(true);
    expect(isMutatingCommand("git push origin main")).toBe(true);
    expect(isMutatingCommand("git merge feature-branch")).toBe(true);
    expect(isMutatingCommand("git rebase main")).toBe(true);
    expect(isMutatingCommand("git reset --hard HEAD~1")).toBe(true);
    expect(isMutatingCommand("git checkout -b new-branch")).toBe(true);
    expect(isMutatingCommand("git branch -D old-branch")).toBe(true);
    expect(isMutatingCommand("git branch --delete old-branch")).toBe(true);
    expect(isMutatingCommand("git branch -m old-branch new-branch")).toBe(true);
    expect(isMutatingCommand("git stash push")).toBe(true);
    expect(isMutatingCommand("git stash clear")).toBe(true);
  });

  test("blocks SQL DDL/DML mutations", () => {
    expect(isMutatingCommand("bq query 'DELETE FROM table WHERE id = 1'")).toBe(true);
    expect(isMutatingCommand("bq query 'INSERT INTO table VALUES (1)'")).toBe(true);
    expect(isMutatingCommand("bq query 'DROP TABLE table'")).toBe(true);
    expect(isMutatingCommand("psql -c 'UPDATE users SET active = false'")).toBe(true);
  });

  test("blocks Cloud write verbs", () => {
    expect(isMutatingCommand("gcloud compute instances delete my-vm")).toBe(true);
    expect(isMutatingCommand("aws s3 rm s3://my-bucket/file.txt")).toBe(true);
    expect(isMutatingCommand("kubectl delete pod my-pod")).toBe(true);
    expect(isMutatingCommand("gh pr create --title 'fix'")).toBe(true);
    expect(isMutatingCommand("gh pr merge 123 --squash")).toBe(true);
  });

  test("blocks HTTP write methods and file output", () => {
    expect(isMutatingCommand("curl -X POST https://api.example.com/submit")).toBe(true);
    expect(isMutatingCommand("curl -d '{\"data\": 1}' https://api.example.com")).toBe(true);
    expect(isMutatingCommand("curl -o downloaded.sh https://example.com/install.sh")).toBe(true);
  });

  test("blocks package managers and build tool installs", () => {
    expect(isMutatingCommand("npm install lodash")).toBe(true);
    expect(isMutatingCommand("bun add fastify")).toBe(true);
    expect(isMutatingCommand("pip install torch")).toBe(true); // wait, let's see if pip is in package managers or if we should add it
  });

  test("blocks mutations inside subshell wrappers", () => {
    expect(isMutatingCommand('bash -c "rm -rf /tmp/data"')).toBe(true);
    expect(isMutatingCommand('sh -c "git commit -m oops"')).toBe(true);
    expect(isMutatingCommand('DEBUG=1 bash -c "rm -rf /tmp/data"')).toBe(true);
  });

  test("blocks php artisan tinker and migrations", () => {
    expect(isMutatingCommand("php artisan tinker")).toBe(true);
    expect(isMutatingCommand("php artisan migrate")).toBe(true);
  });
});

describe("plan-build: MCP tool gating", () => {
  test("allows read-only MCP actions (get, list, search, describe, query)", () => {
    expect(isMcpMutationTool("mcp__linear__get_issue")).toBe(false);
    expect(isMcpMutationTool("mcp__github__list_pull_requests")).toBe(false);
    expect(isMcpMutationTool("mcp__qdrant__search_points")).toBe(false);
    expect(isMcpMutationTool("mcp__datadog__query_metrics")).toBe(false);
  });

  test("blocks mutating MCP actions (create, update, delete, upsert, post)", () => {
    expect(isMcpMutationTool("mcp__linear__create_issue")).toBe(true);
    expect(isMcpMutationTool("mcp__linear__update_issue")).toBe(true);
    expect(isMcpMutationTool("mcp__qdrant__upsert_points")).toBe(true);
    expect(isMcpMutationTool("mcp__qdrant__delete_points")).toBe(true);
    expect(isMcpMutationTool("mcp__github__create_pull_request")).toBe(true);
    expect(isMcpMutationTool("mcp__betterstack__post_incident")).toBe(true);
  });
});
