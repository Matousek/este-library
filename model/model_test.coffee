trimSetter = (value) ->
  goog.string.trim value || ''

RequiredValidator = ->
RequiredValidator::isValidable = ->
  true
RequiredValidator::validate = ->
  switch goog.typeOf @value
    when 'string'
      goog.string.trim(@value + '').length > 0
    when 'array'
      @value.length > 0
    else
      @value?

requiredValidator = ->
  new RequiredValidator

class Person extends este.Model

  constructor: (json, randomStringGenerator) ->
    super json, randomStringGenerator

  defaults:
    'title': ''
    'defaultFoo': 1

  schema:
    'firstName':
      'set': trimSetter
      'validators': [
        requiredValidator
      ]
    'lastName':
      'validators': [
        requiredValidator
      ]
    'name':
      'meta': (self) -> self.get('firstName') + ' ' + self.get('lastName')
    'age':
      'get': (age) -> Number age

suite 'este.Model', ->

  json = null
  person = null

  setup ->
    json =
      'firstName': 'Joe'
      'lastName': 'Satriani'
      'age': '55'
    idGenerator = -> 1
    person = new Person json, idGenerator

  suite 'constructor', ->
    test 'should work', ->
      assert.instanceOf person, Person

    test 'should assign _cid', ->
      assert.equal person.get('_cid'), 1

    test 'should assign id', ->
      person = new Person 'id': 'foo'
      assert.equal person.get('id'), 'foo'
      assert.equal person.getId(), 'foo'

    test 'should create attributes', ->
      person = new Person
      assert.isUndefined person.get 'firstName'

    test 'should return passed attributes', ->
      assert.equal person.get('firstName'), 'Joe'
      assert.equal person.get('lastName'), 'Satriani'
      assert.equal person.get('age'), 55

    test 'should set defaults', ->
      assert.equal person.get('defaultFoo'), 1
      assert.strictEqual person.get('title'), ''

    test 'should set defaults before json', ->
      person = new Person 'defaultFoo': 2
      assert.equal person.get('defaultFoo'), 2

  suite 'instance', ->
    test 'should have string url property', ->
      assert.isString person.url

  suite 'set and get', ->
    test 'should work for one attribute', ->
      person.set 'age', 35
      assert.strictEqual person.get('age'), 35

    test 'should work for attributes', ->
      person.set 'age': 35, 'firstName': 'Pepa'
      assert.strictEqual person.get('age'), 35
      assert.strictEqual person.get('firstName'), 'Pepa'

  suite 'get', ->
    test 'should accept array and return object', ->
      assert.deepEqual person.get(['age', 'firstName']),
        'age': 55
        'firstName': 'Joe'

  suite 'set', ->
    test 'should no changes occur if the validation fails', ->
      assert.equal person.get('firstName'), 'Joe'
      person.set
        firstName: 'Pepa'
        lastName: ''
      assert.equal person.get('firstName'), 'Joe'
      assert.equal person.get('lastName'), 'Satriani'

  suite 'toJson', ->
    suite 'true', ->
      test 'should return undefined name and _cid for model', ->
        json = person.toJson true
        assert.deepEqual json,
          'title': ''
          'firstName': 'Joe'
          'lastName': 'Satriani'
          'age': '55'
          'defaultFoo': 1

      test 'should return undefined name and _cid for empty model', ->
        person = new Person
        json = person.toJson true
        assert.deepEqual json,
          'title': ''
          'defaultFoo': 1

    suite 'false', ->
      test 'should return name and _cid for model', ->
        json = person.toJson()
        assert.deepEqual json,
          '_cid': 1
          'title': ''
          'firstName': 'Joe'
          'lastName': 'Satriani'
          'name': 'Joe Satriani'
          'age': 55
          'defaultFoo': 1

      test 'should return name and _cid for empty model', ->
        person = new Person null, -> 1
        json = person.toJson()
        assert.deepEqual json,
          '_cid': 1
          'title': ''
          'name': 'undefined undefined'
          'defaultFoo': 1

    suite 'on model with attribute with toJson too', ->
      test 'should serialize attribute too', ->
        cid = 0
        model = new este.Model null, -> ++cid
        innerModel = new este.Model null, -> 1
        innerModel.set 'b', 'c'
        model.set 'a', innerModel
        assert.deepEqual model.toJson(),
          _cid: 1
          a:
            _cid: 1
            b: 'c'

      test 'should raw serialize attribute too', ->
        cid = 0
        model = new este.Model null, -> ++cid
        innerModel = new este.Model null, -> 1
        innerModel.set 'b', 'c'
        model.set 'a', innerModel
        assert.deepEqual model.toJson(true),
          a:
            b: 'c'

    test 'should be possible to set null or undefined value', ->
      person.set 'title', null
      person.set 'defaultFoo', undefined
      json = person.toJson true
      assert.deepEqual json,
        'title': null
        'firstName': 'Joe'
        'lastName': 'Satriani'
        'age': '55'
        'defaultFoo': undefined

  suite 'has', ->
    test 'should work', ->
      assert.isTrue person.has 'age'
      assert.isFalse person.has 'fooBlaBlaFoo'

    test 'should work even for keys which are defined on Object.prototype.', ->
      assert.isFalse person.has 'toString'
      assert.isFalse person.has 'constructor'
      assert.isFalse person.has '__proto__'
      # etc. from Object.prototype

    test 'should work for meta properties too', ->
      assert.isTrue person.has 'name'

  suite 'remove', ->
    test 'should work', ->
      assert.isFalse person.has 'fok'
      assert.isFalse person.remove 'fok'

      assert.isTrue person.has 'age'
      assert.isTrue person.remove 'age'
      assert.isFalse person.has 'age'

  suite 'schema', ->
    suite 'set', ->
      test 'should work as formater before set', ->
        person.set 'firstName', '  whitespaces '
        assert.equal person.get('firstName'), 'whitespaces'

    suite 'get', ->
      test 'should work as formater after get', ->
        person.set 'age', '1d23'
        assert.isNumber person.get 'age'

  suite 'change event', ->
    test 'should be dispatched if value change', (done) ->
      goog.events.listen person, 'change', (e) ->
        assert.deepEqual e.changed, age: 'foo'
        assert.equal e.model, person
        done()
      person.set 'age', 'foo'

    test 'should not be dispatched if value hasnt changed', ->
      called = false
      goog.events.listen person, 'change', (e) ->
        called = true
      person.set 'age', 55
      assert.isFalse called

    test 'should be dispatched if value is removed', ->
      called = false
      goog.events.listen person, 'change', (e) ->
        called = true
      person.remove 'age'
      assert.isTrue called

  suite 'update event', ->
    test 'should be dispatched if value change', (done) ->
      goog.events.listen person, 'update', (e) ->
        done()
      person.set 'age', 'foo'

    test 'should not be dispatched if value hasnt changed', ->
      called = false
      goog.events.listen person, 'update', (e) ->
        called = true
      person.set 'age', 55
      assert.isFalse called

    test 'should be dispatched if value is removed', ->
      called = false
      goog.events.listen person, 'update', (e) ->
        called = true
      person.remove 'age'
      assert.isTrue called

  suite 'meta', ->
    test 'should define meta attribute', ->
      assert.equal person.get('name'), 'Joe Satriani'

  suite 'bubbling events', ->
    test 'from inner model should work', ->
      called = 0
      innerModel = new Person
      person.set 'inner', innerModel
      goog.events.listen person, 'change', (e) ->
        called++
      innerModel.set 'name', 'foo'
      person.remove 'inner', innerModel
      innerModel.set 'name', 'foo'
      assert.equal called, 2

    test 'from inner model (within other model) should work', ->
      called = 0
      innerModel = new Person
      someOtherPerson = new Person
      person.set 'inner', innerModel
      someOtherPerson.set 'inner', innerModel
      goog.events.listen person, 'change', (e) ->
        called++
      innerModel.set 'name', 'foo'
      person.remove 'inner', innerModel
      innerModel.set 'name', 'foo'
      assert.equal called, 2

  suite 'errors', ->
    suite 'set', ->
      test 'should return correct errors', ->
        errors = person.set()
        assert.isNull errors

        errors = person.set 'firstName', ''
        assert.isArray errors
        assert.lengthOf errors, 1
        assert.instanceOf errors[0], RequiredValidator
        assert.equal errors[0].model, person
        assert.equal errors[0].key, 'firstName'
        assert.equal errors[0].value, ''
        assert.equal person.get('firstName'), 'Joe'

        errors = person.set 'firstName', 'Pepa'
        assert.deepEqual errors, null

        errors = person.set
          'firstName': 'Pepa'
          'lastName': 'Zdepa'
        assert.deepEqual errors, null

        errors = person.set
          'firstName': ''
          'lastName': ' '
        assert.isArray errors
        assert.lengthOf errors, 2
        assert.instanceOf errors[0], RequiredValidator
        assert.instanceOf errors[1], RequiredValidator
        assert.equal errors[0].model, person
        assert.equal errors[0].key, 'firstName'
        assert.equal errors[0].value, ''
        assert.equal errors[1].model, person
        assert.equal errors[1].key, 'lastName'
        assert.equal errors[1].value, ' '

    suite 'validate', ->
      test 'should return correct errors', ->
        errors = person.validate()
        assert.isNull errors

        person = new Person
        errors = person.validate()
        assert.isArray errors
        assert.lengthOf errors, 2
        assert.instanceOf errors[0], RequiredValidator
        assert.instanceOf errors[1], RequiredValidator
        assert.equal errors[0].model, person
        assert.equal errors[0].key, 'firstName'
        assert.equal errors[0].value, undefined
        assert.equal errors[1].model, person
        assert.equal errors[1].key, 'lastName'
        assert.equal errors[1].value, undefined

        person.set 'firstName', 'Pepa'

        errors = person.validate()
        assert.lengthOf errors, 1
        assert.instanceOf errors[0], RequiredValidator
        assert.equal errors[0].model, person
        assert.equal errors[0].key, 'lastName'
        assert.equal errors[0].value, undefined

  suite 'idAttribute', ->
    test 'should allow to define alternate id', ->
      person = new Person
      person.idAttribute = '_id'
      person.setId '123'
      assert.equal person.getId(), '123'

  suite 'createUrl', ->
    suite 'without collection', ->
      test 'should work for model without id', ->
        assert.equal person.createUrl(), '/models'

      test 'should work for model with id', ->
        person.setId 123
        assert.equal person.createUrl(), '/models/123'

      test 'should work for model with url defined as function', ->
        person.url = -> '/foos'
        person.setId 123
        assert.equal person.createUrl(), '/foos/123'

    suite 'with collection', ->
      test 'should work for model without id', ->
        collection = getUrl: -> '/todos'
        assert.equal person.createUrl(collection), '/todos'

      test 'should work for model with id', ->
        person.setId 123
        collection = getUrl: -> '/todos'
        assert.equal person.createUrl(collection), '/todos/123'

  suite 'setId', ->
    test 'should be immutable if defined in constructor then again', (done) ->
      person = new Person 'id': 'foo'
      try
        person.setId 'bla'
      catch e
        done()

    test 'should be immutable if defined twice', (done) ->
      person = new Person
      person.setId 'foo'
      try
        person.setId 'bla'
      catch e
        done()

    test 'should not dispatch change event', ->
      person = new Person
      dispatched = false
      goog.events.listen person, 'change', ->
        dispatched = true
      person.setId 123
      assert.isFalse dispatched

    test 'should not dispatch update event', ->
      person = new Person
      dispatched = false
      goog.events.listen person, 'update', ->
        dispatched = true
      person.setId 123
      assert.isFalse dispatched

  suite 'getId', ->
    test 'should return empty string for model without id', ->
      assert.equal person.getId(), ''

    test 'should return string id for model with id', ->
      person.setId 123
      assert.equal person.getId(), '123'

  suite 'nested idAttribute', ->
    test 'should allow to set nested mongodb like id via set method', ->
      model = new este.Model
      model.idAttribute = '_id.$oid'
      model.set '_id': '$oid': 123
      assert.equal model.getId(), '123'

    test 'should allow to set nested mongodb like id via setId method', ->
      model = new este.Model
      model.idAttribute = '_id.$oid'
      model.setId 123
      assert.equal model.getId(), '123'
      assert.deepEqual model.toJson(true),
        '_id': '$oid': 123

  suite 'Model.equal', ->
    test 'should work', ->
      assert.isTrue este.Model.equal null, null
      assert.isTrue este.Model.equal undefined, undefined

      assert.isTrue este.Model.equal 1, 1
      assert.isFalse este.Model.equal 1, 2

      model1 = new este.Model a: 1, -> 1
      model2 = new este.Model a: 1, -> 1
      assert.isTrue este.Model.equal model1, model2

      # plain object should be checked via este.json.equal
      model1 = a: '1'
      model2 = a: '1'
      assert.isTrue este.Model.equal model1, model2

      model1 = a: '1'
      model2 = a: '2'
      assert.isFalse este.Model.equal model1, model2

      # plain array should be checked via este.json.equal
      model1 = [1]
      model2 = [1]
      assert.isTrue este.Model.equal model1, model2

      model1 = [1]
      model2 = [2]
      assert.isFalse este.Model.equal model1, model2