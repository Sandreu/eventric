> Not released yet. This hint will disappear with version 0.1.0.


![eventric logo](https://raw.githubusercontent.com/wiki/efacilitation/eventric/eventric_logo.png)

## Introduction [![Build Status](https://travis-ci.org/efacilitation/eventric.svg?branch=master)](https://travis-ci.org/efacilitation/eventric)

**eventric.js** is a JavaScript Framework (written in CoffeeScript) which helps developers to build web applications based on Domain-driven Design and Layered Architecture. It is an alternative to [MVC](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller)+[CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) where you put a lot of effort in defining your data structure and so often end up with an [anemic domain model](http://www.martinfowler.com/bliki/AnemicDomainModel.html).


Information regarding the API and more can be found in the [Wiki](https://github.com/efacilitation/eventric/wiki).


## Philosophy

* Emphasize [Domain-driven design](https://www.goodreads.com/book/show/179133.Domain_Driven_Design), [Event-driven architecture](https://www.goodreads.com/book/show/12369902-event-centric) and [Task-based UIs](http://cqrs.wordpress.com/documents/task-based-ui).
* Put the the Domain Model in the very center of Layered Architecture ([Onion](http://jeffreypalermo.com/blog/the-onion-architecture-part-1/) / [Hexagonal](http://alistair.cockburn.us/Hexagonal+architecture))
* Explicitly set boundaries for parts of your application ([BoundedContexts](https://en.wikipedia.org/wiki/Domain-driven_design#Bounded_context) / [MicroServices](http://martinfowler.com/articles/microservices.html))
* Separation of concerns using Commands and Queries ([CQRS](http://msdn.microsoft.com/en-us/library/jj554200.aspx))
* Capture all changes to your application state as a sequence of events ([EventSourcing](http://martinfowler.com/eaaDev/EventSourcing.html) / [DomainEvents](http://www.udidahan.com/2009/06/14/domain-events-salvation/))


## Quick Start

Basically we define a behavioural API using `queries` and `commands` which result in series of `DomainEvents` consisting of properties that changed inside `Aggregates`. These `DomainEvents` define the state of our application. Since eventric.js runs with NodeJS as well as in the Browser, you can persist `DomainEvents` either directly into the `EventStore` or send them first over a `RemoteService`. The `RemoteService` can also be used to access your API remotely. This makes eventric.js really useful for distributed applications and sharing code between Server and Client.

Having discussed the upcoming **TodoApp Project** with the Business-Experts and fellow Developers and decided to give eventric.js a go, it got clear that we needed a `BoundedContext` named `Collaboration` as part of our application first.


### [Setup BoundedContext](https://github.com/efacilitation/eventric/wiki/eventric#eventricboundedcontext)

> Hint: You should `npm install eventric` and `npm install eventric-store-mongodb` first.

Let's get right into it and create our `BoundedContext`

```javascript
eventric = require('eventric');

collaborationContext = eventric.boundedContext();
```

### [Adding Aggregate](https://github.com/efacilitation/eventric/wiki/BoundedContext#addaggregate)

Now that we created the `collaborationContext` let's add our `Todo` Aggregate, consisting of a simple `changeDescription` method.

```javascript
collaborationContext.addAggregate('Todo', {
  changeDescription: function(description) {
    this.description = description;
  }
});
```
> Hint: values assigned to `this.` are automatically part of the generated `DomainEvent`

### [Adding Commands](https://github.com/efacilitation/eventric/wiki/BoundedContext#addcommand)

To actually work with the `BoundedContext` from the outside world we need `commands` and `queries`. Let's start by adding a simple `command` that will create an instance of our `Todo` Aggregate.

```javascript
collaborationContext.addCommand('createTodo', function(params, callback) {
  this.aggregate.create('Todo', callback);
});
```
> Hint: `this.aggregate` is dependency injected

It would be nice if we could change the description of the `Todo`, so let's add this `command` too.

```javascript
collaborationContext.addCommand('changeTodoDescription', function(params, callback) {
  this.aggregate.command('Todo', params.id, 'changeDescription', params.description, callback);
});
```
> Hint: If successful this will trigger a *Todo:changeDescription* `DomainEvent`

### [Adding Query](https://github.com/efacilitation/eventric/wiki/BoundedContext#addquery)

And last but not least we want the ability to `query` for a `Todo` by its id.

```javascript
collaborationContext.addQuery('getTodoById', function(params, callback) {
  this.repository('Todo').findById(params.id, callback);
});
```
> Hint: `this.repository` is dependency injected

### Executing [Commands](https://github.com/efacilitation/eventric/wiki/BoundedContext#command) and [Queries](https://github.com/efacilitation/eventric/wiki/BoundedContext#query)

Initialize the `collaborationContext`, create a `Todo`, change the description of it and finally query the description again.

```javascript
collaborationContext.initialize(function() {
  collaborationContext.command({
    name: 'createTodo'
  },
  function(err, todoId) {
    collaborationContext.command({
      name: 'changeTodoDescription',
      params: {
        id: todoId,
        description: 'Do something'
      }
    },
    function(err, status) {
      collaborationContext.query({
        name: 'getTodoById',
        params: {
          id: todoId
        }
      },
      function(err, readTodo) {
          console.log(readTodo.description);
      })
    });
  });

});
```
> `eventric` will implement [promises](https://github.com/kriskowal/q) to avoid such a "[Pyramid of Doom](http://calculist.org/blog/2011/12/14/why-coroutines-wont-work-on-the-web/)" in the future.

This will output `Do something`. Your `Todo` Aggregate is now persisted using EventSourcing.

Congratulations, you have successfully applied DDD (tactical+technical) and CQRS! :)


## Running Tests

To execute all (client+server) tests, use:

```shell
gulp spec
```

You can watch for file-changes with

```shell
NODE_ENV=workstation gulp watch
```


## License

MIT

Copyright (c) 2013-2014 SixSteps Team, eFa GmbH
