describe 'ReadAggregateRepositorySpec', ->

  sinon    = require 'sinon'
  expect   = require 'expect.js'
  eventric = require 'eventric'

  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  EventStore              = eventric 'MongoDBEventStore'

  class ReadFoo extends ReadAggregateRoot
    @prop 'name'


  sandbox = null
  readAggregateRepository = null
  EventStoreStub = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

    EventStoreStub = sinon.createStubInstance EventStore

    readAggregateRepository = new ReadAggregateRepository 'Foo', EventStoreStub
    readAggregateRepository.registerClass 'ReadFoo', ReadFoo

  afterEach ->
    sandbox.restore()

  describe '#findById', ->

    it 'should return a instantiated ReadAggregate', ->
      readAggregateRepository.findById 'ReadFoo', 23, (err, readAggregate) ->
        expect(readAggregate).to.be.a ReadFoo

    it 'should ask the adapter for the DomainEvents matching the AggregateId', ->
      readAggregateRepository.findById 'ReadFoo', 23, ->
      expect(EventStoreStub.find.calledWith('Foo', {'aggregate.id': 23})).to.be.ok()

    it 'should return a instantiated ReadAggregate containing the applied DomainEvents', ->
      readAggregate = readAggregateRepository.findById 'ReadFoo', 23, (err, readAggregate) ->
        expect(readAggregate.name).to.be 'John'


  describe '#find', ->

    query        = null
    findIdsStub  = null
    findByIdStub = null
    adapterStub  = null
    beforeEach ->
      query = {}
      findIdsStub  = sandbox.stub readAggregateRepository, 'findIds'
      findIdsStub.yields null, [42]
      findByIdStub = sandbox.stub readAggregateRepository, 'findById'
      findByIdStub.yields null, new ReadFoo


    it 'should call findIds to get all aggregateIds matching the query', (done) ->
      # stub _findAggregateIdsByDomainEventCriteria to return an example AggregateId
      readAggregateRepository.find 'ReadFoo', query, ->
        expect(findIdsStub.calledWith 'ReadFoo', query).to.be.ok()
        done()

    it 'should call findById for every aggregateId found', (done) ->
      readAggregateRepository.find 'ReadFoo', query, ->
        expect(findByIdStub.calledWith 'ReadFoo', 42).to.be.ok()
        done()

    it 'should return ReadAggregate instances matching the given query', (done) ->
      readAggregateRepository.find 'ReadFoo', query, (err, readAggregates) ->
        expect(readAggregates.length).to.be 1
        expect(readAggregates[0]).to.be.a ReadFoo
        done()

  describe.skip '#findOne', ->

    it 'should call find and return only one result'


  describe.skip '#findIds', ->

    it 'should return all AggregateIds matching the given query-criteria', ->
      criteria = {}
      sandbox.stub readAggregateRepository._adapter, '_findAggregateIdsByDomainEventCriteria', -> [42]
      aggregateIds = readAggregateRepository.findIds criteria
      expect(aggregateIds.length).to.be 1
      expect(aggregateIds[0]).to.be 42