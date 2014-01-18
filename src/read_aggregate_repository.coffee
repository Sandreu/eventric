Repository = require('eventric')('Repository')

class ReadAggregateRepository extends Repository

  constructor: (@_aggregateName, @_eventStore) ->

  findById: (readAggregateName, aggregateId, callback) =>
    # create the ReadAggregate instance
    ReadAggregateClass = @getClass readAggregateName

    if not ReadAggregateClass
      err = new Error "Tried 'findById' on not registered ReadAggregate '#{readAggregateName}'"
      callback err, null
      return

    @_eventStore.find @_aggregateName, { 'aggregate.id': aggregateId }, (err, domainEvents) =>
      return callback err, null if err
      return callback null, [] if domainEvents.length == 0

      readAggregate = new ReadAggregateClass

      # apply the domainevents on the ReadAggregate
      readAggregate.applyChanges domainEvent.aggregate.changed for domainEvent in domainEvents
      readAggregate.id = aggregateId

      # return the readAggregate
      callback null, readAggregate


  find: (readAggregateName, query, callback) ->
    # get ReadAggregates matching the query
    @findIds readAggregateName, query, (err, aggregateIds) =>
      return callback err, null if err

      # TODO return multiple ReadAggregates when multiple aggregateIds are found
      @findById readAggregateName, aggregateIds[0], (err, readAggregate) =>
        return callback err, null if err
        return callback null, [] if readAggregate.length == 0

        results = [readAggregate]

        callback null, results


  findOne: (readAggregateName, query, callback) ->
    @find readAggregateName, query, (err, results) =>
      return callback err, null if err
      return callback null, false if results.length == 0
      callback null, results[0]


  findIds: (readAggregateName, query, callback) =>
    # ask the adapter to find the ids and return them
    @_eventStore.find @_aggregateName, query, { 'aggregate.id': 1 }, (err, results) =>
      return callback err, null if err

      aggregateIds = []
      aggregateIds.push result.aggregate.id for result in results when result.aggregate.id not in aggregateIds

      callback null, aggregateIds


module.exports = ReadAggregateRepository