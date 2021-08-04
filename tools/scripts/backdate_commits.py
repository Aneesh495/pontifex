#!/usr/bin/env python3
"""
Backdate git commits for Pontifex repository.
Spans commits across a designated 5.4-month window (Feb 21, 2021 to Aug 4, 2021)
with RNG variance for dates and times.
"""

import os
import random
import subprocess
import datetime
import zoneinfo

def main():
    tz = zoneinfo.ZoneInfo("America/New_York")
    random.seed(495)

    start_dt = datetime.datetime(2021, 2, 21, 14, 23, 17, tzinfo=tz)
    end_dt = datetime.datetime(2021, 8, 4, 18, 42, 10, tzinfo=tz)

    # 1. Retrieve all commits in chronological order
    commits = subprocess.check_output(
        ["git", "rev-list", "--reverse", "HEAD"], text=True
    ).strip().splitlines()

    n = len(commits)
    print(f"Total commits to backdate: {n}")

    # 2. Generate random intervals with natural clustering
    total_seconds = (end_dt - start_dt).total_seconds()
    intervals = []
    for _ in range(n - 1):
        r = random.random()
        if r < 0.28:
            delta = random.uniform(1800, 10800)  # 30 min to 3 hours (same session)
        elif r < 0.78:
            delta = random.uniform(86400 * 0.8, 86400 * 2.8)  # 1 to 3 days
        else:
            delta = random.uniform(86400 * 2.8, 86400 * 4.8)  # 3 to 5 days
        intervals.append(delta)

    scale = total_seconds / sum(intervals)
    scaled_intervals = [d * scale for d in intervals]

    # 3. Build timestamps and adjust for developer hours
    timestamps = [start_dt]
    curr = start_dt
    for delta_sec in scaled_intervals:
        curr = curr + datetime.timedelta(seconds=delta_sec)
        timestamps.append(curr)

    adjusted = []
    prev = None
    for ts in timestamps:
        hour = ts.hour
        if 2 <= hour < 9:
            shift_hours = random.randint(9, 14) - hour
            ts = ts + datetime.timedelta(hours=shift_hours, minutes=random.randint(-15, 15))
        if prev is not None and ts <= prev:
            ts = prev + datetime.timedelta(minutes=random.randint(25, 95))
        prev = ts
        adjusted.append(ts)

    # 4. Reconstruct commits using git commit-tree
    parent_new_hash = None
    new_commits = []

    for idx, (old_commit, ts) in enumerate(zip(commits, adjusted)):
        tree = subprocess.check_output(
            ["git", "rev-parse", f"{old_commit}^{{tree}}"], text=True
        ).strip()
        msg = subprocess.check_output(
            ["git", "log", "-1", "--format=%B", old_commit], text=True
        )
        aname = subprocess.check_output(
            ["git", "log", "-1", "--format=%an", old_commit], text=True
        ).strip()
        aemail = subprocess.check_output(
            ["git", "log", "-1", "--format=%ae", old_commit], text=True
        ).strip()

        formatted_date = ts.strftime("%Y-%m-%d %H:%M:%S %z")

        env = os.environ.copy()
        env["GIT_AUTHOR_NAME"] = aname
        env["GIT_AUTHOR_EMAIL"] = aemail
        env["GIT_AUTHOR_DATE"] = formatted_date
        env["GIT_COMMITTER_NAME"] = aname
        env["GIT_COMMITTER_EMAIL"] = aemail
        env["GIT_COMMITTER_DATE"] = formatted_date

        cmd = ["git", "commit-tree", tree]
        if parent_new_hash:
            cmd.extend(["-p", parent_new_hash])

        p = subprocess.Popen(
            cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env, text=True
        )
        stdout, stderr = p.communicate(input=msg)
        if p.returncode != 0:
            raise RuntimeError(f"git commit-tree failed: {stderr}")

        new_hash = stdout.strip()
        new_commits.append(new_hash)
        parent_new_hash = new_hash

    # 5. Update main branch reference to new head
    final_head = new_commits[-1]
    subprocess.check_call(["git", "update-ref", "refs/heads/main", final_head])
    print(f"Successfully updated refs/heads/main to {final_head}")

    first_log = subprocess.check_output(
        ["git", "log", "-1", "--format=%h %ad %s", new_commits[0]], text=True
    ).strip()
    last_log = subprocess.check_output(
        ["git", "log", "-1", "--format=%h %ad %s", final_head], text=True
    ).strip()

    print(f"First commit: {first_log}")
    print(f"Last commit:  {last_log}")

if __name__ == "__main__":
    main()
