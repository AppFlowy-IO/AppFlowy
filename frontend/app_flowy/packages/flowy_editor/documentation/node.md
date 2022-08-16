# Node

Node is the data structure used to describe the rendering information.

## JSON

FlowyEditor uses a specific JSON data format to describe documents. 

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/7bd4be04-82c8-458c-9321-a5ed79aa94ed/Untitled.png)

Each part of a document can be converted by the above format, for example

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/930ae42a-055f-4d79-bc83-921fa7845b4d/Untitled.png)

An outermost layer is an object whose type is ‘editor’, which is used as the entry for FlowyEditor to parse data. And children are the details of the document.

## Node

The state tree is an in-memory mapping of a JSON file, consisting of nodes**,** and its property names are consistent with JSON keys. So each node must contain fields for **type, attributes, and children**.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/04986ead-9bb6-4f32-9584-190bd70ce5e8/Untitled.png)

### **Type**

Type is an identifier describing the current node. The render system distributes to the corresponding builders according to the type. Note that nodes whose type is equal to ‘text’ are used as internal reserved fields.

### Attributes

Attributes is an information data describing the current node. We reserve the **subtype** field to describe the derived type of the current node, and other fields can be extended at will.

### Children

Children are the child node describing the current node. We assume that each node can nest the other nodes.

We encapsulate operations on Node, such as insert, delete and modify info StateTree. It holds the root node and is responsible for converting between JSON to and from it.

### Path

Path is an array of integer numbers to locate a node in the state tree. For example, [0, 1] represents the second child of the first child of the root node. 

### Selection

### Reversed field

**Type**

- text

**Attributes**

- subtype