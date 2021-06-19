# AppFlowy Architecture
This documentation introduces the Domain-Driven Design and the design of AppFlowy. Feel free to skip the first part
if you know what Domain-Driven Design is.
* Basic Concepts
    * Layered architecture
    * Domain Driven Design
    
* AppFlowy Design
    * Overview
    * Operation Flow
    * Create
    * Read
    * Update
    * Delete
    
# Basic Concepts

## Layered architecture
The most common architecture pattern is the layered architecture pattern, known as the n-tier architecture pattern.
Partition the software into `layers` to reduce the complexity. Each layer of the layered architecture pattern has a
specific role and responsibility.

## Domain Driven Design
For many architects, the process of data modeling is driven by intuition. However, there are well-formulated methodologies
for approaching it more formally. I recommend the [Domain-Driven Design](https://en.wikipedia.org/wiki/Domain-driven_design)
and choose it as AppFlowy architecture. 

DDD consists of four layers.

```
    ┌──────────────────────────────────────────────────┐         ─────────▶
    │                Presentation Layer                │──┐      Dependency
    └──────────────────────────────────────────────────┘  │
                              │                           │
                              ▼                           │
    ┌──────────────────────────────────────────────────┐  │
    │                Application Layer                 │  │
    └──────────────────────────────────────────────────┘  │
                              │                           │
                              ▼                           │
    ┌──────────────────────────────────────────────────┐  │
    │                   Domain Layer                   │◀─┘
    └──────────────────────────────────────────────────┘
                              ▲
                              │
    ┌──────────────────────────────────────────────────┐
    │               Infrastructure Layer               │
    └──────────────────────────────────────────────────┘
    
                 ▲
                 │
    Level of     ├───────────────────┐
    Abstraction  │ Presentation      │
                 ├───────────────────┴───────┐
                 │ Application               │
                 ├───────────────────────────┴─────────┐
                 │ Domain                              │
                 ├─────────────────────────────────────┴────────┐
                 │ Infrastructure                               │
                 └──────────────────────────────────────────────┴─────▶
                                                           Complexity
```

**Presentation**: 
* Responsible for presenting information to the user and interpreting user commands.
* Consists of Widgets and also the state of the Widgets.
   
**Application**:
* Defines the jobs the software is supposed to do. (Shouldn't find any UI code or network code)
* Coordinates the application activity and delegates work to the next layer down.
* It doesn't contain any complex business logic but the basic validation on the user input before
  passing to the other layer.   
  
**Domain**: 
* Responsible for representing concepts of the business.
* Manages the business state or delegated to the infrastructure layer.
* Self contained and it doesn't depend on any other layers. Domain should be well isolated from the
  other layers.

**Infrastructure**: 

This layer acts as a supporting library for all the other layers. It deals with APIs, 
databases and network, etc.

DDD classifies data as referenceable objects, or entities, and non-referenceable objects, or values.

**Entity** 

user, order, book, table. They are referenceable because they carry an identity which 
allows us to reference them.

**Value**

email, phone number, name, age, description. They can't be referenced. They can be only included into
entities and serve as attributes. Values could be simple or could be composite.

**Aggregate** 

entities can be grouped into aggregates. Aggregates can simplify the model by accessing th entire
aggregate. For instance, Table has lots of row. Each row using the table_id to reference to the 
table. TableAggregate includes two entities: Table and the Row.

```
     TableAggregate
    ┌────────────────────────────────────────────────────────────────┐
    │                                                                │
    │  ┌────────────────────┐         ┌─────────────────────────┐    │
    │  │struct Table {      │         │struct Row {             │    │
    │  │    id: String,     │         │    table_id: String,    │    │
    │  │    desc: String,   │◀▶───────│}                        │    │
    │  │}                   │         │                         │    │
    │  └────────────────────┘         └─────────────────────────┘    │
    │                                                                │
    └────────────────────────────────────────────────────────────────┘
```

DDD also introduces `Service` and `Repository`.

**Service**

When a significant process of transformation in the domain is not a natural responsibility of an `Entity` or `Value object`, add
an operation to the model as standalone interface declared as a Service. For instance: The `Value object`, EmailAddress, 
uses the function `validateEmailAddress` to verify the email address is valid or not. `Service` exists in Application, Domain and
Infrastructure.

```
class EmailAddress  {
  final Either<Failure<String>, String> value;

  factory EmailAddress(String? input) {
    return EmailAddress._(
      validateEmailAddress(input),
    );
  }
  
  const EmailAddress._(this.value);
}


Either<Failure<String>, String> validateEmailAddress(String? input) {
  ...
}
```

**Repository**

Repository offer an interface to retrieve and persist aggregates. They hide the database or network details from the domain.
The Repository interfaces are declared in the Domain Layer, but the repositories themselves are implemented in the Infrastructure Layer.
You can replace the interface implementation without impacting the domain layer. For instance:

```
// Interface:
abstract class AuthInterface {
    ...
}

// Implementation
class AuthRepository implements AuthInterface {
    ...
}
```
More often than not, the repository interface can be divided into sub-repository in order to reduce the complexity. 

## AppFlowy Design

The AppFlowy Client consists of lots of modules. Each of them follows the DDD design pattern and using [dependency injection](https://levelup.gitconnected.com/dependency-injection-in-swift-bc16d66b038b)
to communication with other module.

```
     Client
    ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                                      │
    │   User                                 Editor                   Setting                              │
    │  ┌───────────────────┐                ┌───────────────────┐    ┌───────────────────┐                 │
    │  │ presentation      │   Dependency   │ presentation      │    │ presentation      │                 │
    │  │                   │   Injection    │                   │    │                   │                 │
    │  │ application       ├───────────────▶│ application       │    │ application       │                 │
    │  │                   │◀───────────────│                   │    │                   │    ◉  ◉  ◉      │
    │  │ domain            │                │ domain            │    │ domain            │                 │
    │  │                   │                │                   │    │                   │                 │
    │  │ Infrastructure    │                │ Infrastructure    │    │ Infrastructure    │                 │
    │  └───────────────────┘                └───────────────────┘    └───────────────────┘                 │
    │            ▲                                                             │                           │
    │            │                       Dependency Injection                  │                           │
    │            └─────────────────────────────────────────────────────────────┘                           │
    │                                                                                                      │
    └──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

Let's dig it how can I construct each module. I take `User` module for demonstration.


# Event-Driven