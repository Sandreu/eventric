describe 'AggregateRepository', ->

  describe.only '#findById', ->

    AggregateRoot = null
    aggregateRepository = null
    eventStoreStub = null
    class Foo
      myFunc: ->
    beforeEach ->
      AggregateRoot = eventric.require 'AggregateRoot'
      sandbox.stub AggregateRoot::, 'applyChanges'

      AggregateRepository = eventric.require 'AggregateRepository'
      class EventStore
        find: ->
        save: ->
      eventStoreStub = sinon.createStubInstance EventStore
      aggregateRepository = new AggregateRepository eventStoreStub
      aggregateRepository.registerAggregateClass 'Foo', Foo


    it 'should ask the EventStore for DomainEvents matching the AggregateId', ->
      aggregateRepository.findById 'Foo', 42, ->
      expect(eventStoreStub.find.calledWith('Foo', {'aggregate.id': 42})).to.be.true


    describe 'given an array of domainEvents from the eventStore', ->

      beforeEach ->
        eventStoreStub.find.yields null, [
          aggregate:
            changed:
              name: 'John'
        ]


      it 'should return a instantiated Aggregate', (done) ->
        aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
          expect(aggregate).to.be.an.instanceof Foo
          done()


      it 'should return a instantiated Aggregate with the correct id', (done) ->
        aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
          expect(aggregate.id).to.be.equal 42
          done()


      it 'should return a instantiated Aggregate with all DomainEvents applied', (done) ->
        aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
          expect(AggregateRoot::applyChanges.calledWith name: 'John').to.be.ok
          done()


    describe 'given no domainEvents from the eventStore', ->

      it 'should call the callback with null, null', (done) ->
        eventStoreStub.find.yields null, []
        aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
          expect(err).to.be.null
          expect(aggregate).to.be.null
          done()
