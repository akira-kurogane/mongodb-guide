+++
title = "The BSON document"
date =  2018-05-31T14:47:29+10:00
draft = true
weight = 5
+++

MongoDB stores both user collections' data and also its system collections' data in one and only one binary format - the BSON format. It is a binary format for serializing objects of arbitrary keys and values, the same as JSON.


  TODO: \[two-column view. JSON two- or three-value object on left, annotated or aligned matching BSON binary values in hex on right]


JSON (and BSON with it) contains key names. This means storage space is consumed by string data of the key names repeated in every object.


  \[psuedo-representation of a RDMBS or pre-RDBMS table row]

  \[ ; id; peer_user_id; create_dt; seq_no; reaction_enum_value ]

  \[ row header; int64; int64; datetime; int32; int32 ] = hdr sz? + 8 + 8 + 8 + 4 + 4 = 32 bytes + header size.


  `{"_id": <int64>, "peer_user_id": <int64>, "create_dt": <datetime>, "seq_no": <int32>, "reaction_enum_value": <int64>}` = BSON hdr fields + 3 (key) + 8 + 13 (key) + 8 + 10 (key) + 8 + 7 (key) + 4 + 20 (key) + 4 = 83 bytes + BSON header fields

Recommendation: use short key names. One- or two-characters ones are easier to work with that long ones in my experience, anyhow.

In practice BSON is the encoding of MongoDB and isn't used in any other software as popular as MongoDB yet. Nonetheless the BSON specification is one thing and MongoDB is another. There are some extra requirements that MongoDB places on any BSON object is will store:

- 16MB maximum size. The BSON specification places no upper limit on the size of data it encodes but the MongoDB database server and the drivers do.
- "\_id" field: Every document saved to a collection will have an "_id" field value. It is the primary key value of all collections. One of an ObjectId() type will be given automatically if none is specified at insert time.

## Datatypes

JSON only supports the same datatypes that a Javascript tokenizer will handle. (If you are Javascript programmer you are no doubt thinking 'But what about other types such as Date?' Surprise- these are not covered by the JSON specification.)

- String (Null-terminated UTF-8)
- Number (JSON does not specify the binary format)
- Boolean
- Null
- Object
- Array


BSON extends to have these necessary datatypes that mostly any database would need:

Number types:

- int32
- int64
- uint64
- Double (8-byte IEEE 754-2008 format)
- Decimal (16-byte IEEE 754-2008 format)
- Datetime (without timezone, i.e. assumed to be UTC always)
- Timestamp
- Generic binary data
- ObjectID (MongoDB uses this type. It would be called a GUID in some other databases that exist.)

BSON also include these (in my opinion) exotic-for-a-database-system datatypes

- Min key
- Max key
- Javascript code (As a UTF8 string, i.e. not in a compiled, runtime-executable format.)
- A few special 'binary types'
- Function (as a compiled, runtime-executable format????)
- UUID
- MD5
