app = angular.module('ProblemPage', ['ProblemsHelper', 'ui.ace', 'Directives', 'LocalStorageModule', 'SimpleCMS.jsrepl', 'SimpleCMS.InteractiveTerminal'])

app.controller('ProblemPage', ['$scope', '$http', '$window', 'localStorageService', 'jsrepl', ($scope, $http, $window, $storage, jsrepl) ->
    # Set default values
    $scope.code = ""
    $scope.alerts = []
    Object.defineProperty $scope.alerts, "add",
      value: (type, message) ->
        if message
          this.push
            type: type
            message: message

    $scope.isNumber = (input) ->
      not isNaN(Number(input))

    $scope.$watch 'problem.id', ->
      if $scope.problem && $scope.problem.id
        $storage.bind($scope, 'code', '', "problem-#{$scope.problem.id}-code")
        $storage.bind($scope, "terminalHistory", [], "terminal-history")

    $scope.aceLoad = (editor) ->
      editor.commands.addCommand
        name: 'run',
        bindKey:
          win: 'Ctrl-B'
          mac: 'Command-B'
        exec: -> $scope.runCode()

      editor.getSession().setTabSize(2)
      editor.getSession().setUseSoftTabs(true)
      editor.getSession().setUseWrapMode(true)

    $scope.submitAll = ->
      submissions = []
      angular.forEach $scope.problem.tasks_attributes, (task) ->
        return if task.solved
        return unless task.submission_allowed

        task.submission ||= {}

        submissions.push
          task_id: task.id
          input: task.submission.input
          code: task.submission.code

      $http.post("/submissions.json", {authenticity_token: $scope.authenticity_token, submissions: submissions})
           .success (data) ->
             for submission in data
              task = task for task in $scope.problem.tasks_attributes when task.id is submission.task_id
              index = $scope.problem.tasks_attributes.indexOf(task)
              task.submission = submission
              task.submissions_left -= 1
              task.attempted = true
              task.solved ||= submission.accepted
              if submission.accepted
                $scope.alerts.add("success", "Test case #{index + 1} accepted.")
              else
                $scope.alerts.add("danger", "Test case #{index + 1} failed.")
           .error ->
            $scope.alerts.add("danger", "Cannot submit your answers. Please refresh the page and try again.")

    $scope.runCode = (code = $scope.code, listeners = {}) ->
      jsrepl.eval(code, listeners)

    $scope.runCodeWithTestCases = ->
      whitelist = (index for index in arguments)

      angular.forEach $scope.problem.tasks_attributes, (task, index) ->
        return if task.json
        return if whitelist.length && whitelist.indexOf(index) < 0

        # TODO We should probably check that task.input itself is a valid Python
        # program before continuing, else, it is likely that the user will see
        # some weird shit error message

        task.submission = {} unless task.submission
        task.submission.input = "" unless task.submission.input
        task.submission.code  = """
                                ### Beginning of injected code
                                #{task.input}
                                ### End of injected code

                                #{$scope.code}
                                """

        stdout = ""

        $scope.runCode task.input,
          before: ->
            jsrepl.writer("Test Case #{index + 1}\n", "jqconsole-system")

        $scope.runCode $scope.code,
          output: (data) -> stdout += data
          after: ->
            $scope.$apply ->
              task.submission.input = stdout
])