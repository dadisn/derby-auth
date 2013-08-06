validator = require('validator/validator-min.js')
check = validator.check
sanitize = validator.sanitize
utils = require('../../utils.coffee')

exports.init = (model) ->
    model = @model
    rootModel = model.parent().parent()
    $groups = rootModel.query('groups', {})
    $groups.fetch (err) ->
        return next(err) if err
        model.set 'groups', $groups.get()
      
exports.create = (model, dom) ->
    model.on 'change', 'username', (username) ->
        return unless username
        try
            check(username).isAlphanumeric();
            model.set('errors.username', '');
        catch err
            model.set('errors.username', 'Ogiltiga tecken')

    model.on 'change', 'email', (email) ->
        return unless email
        try
            check(email).isEmail()
            model.set('errors.email', '')
        catch err
            model.set('errors.email', 'Ogiltig e-post')

    model.on 'change', 'passwordConfirmation', (passwordConfirmation) ->
        return unless passwordConfirmation
        try
            check(passwordConfirmation).equals(model.get('password'))
            model.set('errors.passwordConfirmation', '')
        catch err
            model.set('errors.passwordConfirmation', 'Lösenorden är inte lika')

    model.on 'change', 'password', (password) ->
        return unless password
        try
            check(password).len(6)
            model.set('errors.password', '')
        catch err
            model.set('errors.password', 'Lösenordet måste vara minst 6 tecken')

    model.on 'change', 'group', (group) ->
        return unless group
        try
            check(group).notEmpty()
            model.set('errors.group', '');
        catch err
            model.set('errors.group', 'Du måste välja användargrupp')

    model.on 'change', 'errors.*', (error) ->
        m = model.get()
        canSubmit = !m.errors.username && !m.errors.email && !m.errors.passwordConfirmation && !m.errors.password && !m.errors.group &&
            !!m.username && !!m.email && !!m.passwordConfirmation && !!m.password && !!m.group
        model.set('canSubmit', canSubmit)

exports.usernameBlur = () ->
    # check username not already registered
    model = @model
    rootModel = model.parent().parent()
    $q = rootModel.query('auths', {'local.username': model.get('username'), $limit: 1})
    $q.fetch (err) ->
        try
            throw new Error(err) if (err)
            throw new Error('Användarnamn redan taget') if $q.get()[0]
        catch err
            model.set('errors.username', err.message)

exports.emailBlur = () ->
    # check email not already registered
    model = @model
    rootModel = model.parent().parent()
    $q = rootModel.query('auths', {'local.email': model.get('email'), $limit:1})
    $q.fetch (err) ->
        try
            throw new Error(err) if (err)
            throw new Error('e-post redan registrerad') if $q.get()[0]
        catch err
            model.set('errors.email', err.message)