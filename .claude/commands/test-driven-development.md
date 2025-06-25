# TDD

### Basic Policy
- 🔴 Red: write tests that fail
- Green: implement the minimum number of tests that will pass
- 🔵 Refactor: refactoring
- Proceed in small steps
- Start with a tentative implementation (a solid write)
- Generalize by triangulation
- If you know the obvious implementation, you can implement it directly
- Constantly update the test list
- Write tests from the point of uncertainty

### TDD Practice Tips
1.**First test**: write tests that fail first (compile errors are ok) 2.
2. **Tentative implementation**: It is OK to write a solid implementation to pass tests (e.g., `return 42`)
3. **Triangulation**: Generalize the second and third test cases
4. **Refactoring**: organize after the test passes
5.**TODO list update**: add to the list as soon as something comes to mind during implementation
6.**One at a time**: Do not write multiple tests at the same time. 7.
7.**Commit**: commit tests as soon as they pass
