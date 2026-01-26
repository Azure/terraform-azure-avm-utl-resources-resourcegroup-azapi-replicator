You have been given a sub task listed in `track.md`, please check:
1. Is the implementation present in the code (not commented out)?
2. Is the variable/argument/output being actively used?
3. If the implementation is commented out, it should be considered NOT implemented.

Check all `.tf` files.

Respond with ONLY ONE of these two words:
- "IMPLEMENTED" if the task is properly implemented and actively used
- "NOT_IMPLEMENTED" if the task is missing, commented out, or not actively used

Some implementation might be removed by accident during acc test, so we have to double check again.

**IMPORTANT**: If you determine the task is NOT_IMPLEMENTED:
1. Open or create the `warning.md` file
2. Add the task ID and task name to the file in the following format:

```
### Task [ID]: [Name]

- **Type**: [Type]
- **Required**: [Required]
- **Issue**: Implementation not found or commented out
```

Do not provide any explanation in your response, just the verdict word "IMPLEMENTED" or "NOT_IMPLEMENTED".