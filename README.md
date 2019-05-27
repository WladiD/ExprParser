# ExprParser
Simple, but flexible expression parser for Delphi. 

There is often a point in the lifetime of a project, where you think, that you absolutely need scripting abilities, because you need a fast way to update the workflow of your application. But sometimes is a script engine a little bit oversized. In my cases it was completely sufficient to publish some context vars, bind some functions and then dynamicly evaluate through a simple expression. The expression can be modified outside without the need for a recompile. Maybe it is also useful for your needs.

ExprParser was forked from JvExprParser <https://github.com/project-jedi/jvcl/blob/master/jvcl/run/JvExprParser.pas>.

Since then it has gained some improvements:
* Speed improvements
* Short-circuit evaluation for boolean expression was introduced. It can be deactivated through `TExprParser.FullBooleanEvaluation := True;`
* The parser was unable to parse float numbers on non-English systems
* Hidden classes was moved from implementation to interface section. This enables it, to traverse the execution tree. This ability is also used in the contained TestSuite project.
* A lot of cases are now covered by unit tests
