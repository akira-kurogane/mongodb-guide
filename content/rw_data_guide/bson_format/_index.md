+++
title = "The data: BSON documents"
description = "The JSON-like data format used in MongoDB"
date =  2018-05-31T14:47:29+10:00
weight = 10
+++

MongoDB stores both user collections' data and also its system collections' data in one and only one binary format - the BSON format.


JSON equivalent | Serialized form in hexadecimal byte values
----------------| ------------------------------------------
&nbsp; | 0x3e = 62 (byte size of this document) as int32<br><tt>3e 00 00 00</tt>
{ | &nbsp;
&nbsp; "\_id" : 7, | (datatype 0x01 = double), (cstring "\_id\0"), (7 as a double floating-point value)<br><tt>01 &nbsp; 5f 69 64 00 &nbsp; 00 00 00 00 00 00 1c 40</tt>
&nbsp; "instr" : "XYZ 3m", | (datatype 0x07 = string), (cstring "instr\0"), ((not-cstring!) string len 0x07 in int32), (byte array "XYZ 3m" (6 bytes) + an extra null byte)<br><tt>02 &nbsp; 69 6e 73 74 72 00 &nbsp; 07 00 00 00 &nbsp; 58 59 5a 20 33 6d 00</tt>
&nbsp; "hval" : 904.72, | (datatype 0x01 = double), (cstring "hval\0"), (904.72 in a double)<br><tt>01 &nbsp; 68 76 61 6c 00 &nbsp; f6 28 5c 8f c2 45 8c 40</tt>
&nbsp; "ts" : ISODate("2019-07-21T01:12:15.348Z") | (type 0x09 UTC datetime), (cstring "ts\0"), (UTC milliseconds since the Unix epoch in an int64)<br><tt>09 &nbsp; 74 73 00 &nbsp; f4 1e 16 12 6c 01 00 00</tt>
} | &nbsp;
&nbsp; | <tt>0x00</tt> datatype indicator for a BSON document<br>N.b. the document type is the only one that has it's type indicator at the end.

{{% expand "Notes on the above example" %}}

- The "cstring" type used for key names means UTF-8 character string with a tailing null byte on the end. This means all valid UTF-8 strings _except_ the case of having a string of one or more null bytes, which is pointless as a key name value anyhow.
- Even though the "\_id" value above looked like an integer to our naked eye, mongo javascript shell made it a 64 bit double float. This happened because I created the document in the (javascript) mongo shell. Depending on your client language you may or not have a floating-point or integer-style value by default; in all client languages you can specify the type if you are more explicity. E.g. in the mongo javascript shell I could have created the \_id value as <tt>new NumberInt(7)</tt>, or NumberLong.
- You probably worked this out: Little-endian byte order is used for all the basic types. I.e. everything that isn't a byte string/array.

{{% /expand %}}

{{% expand "shell example with bsondump of a single-doc collection" %}}
```bash
~$ mongodump <connection_args_to_default_test_db> --eval 'db.foo.insert({"_id": 7, "instr": "XYZ 3m", "hval": 904.72, "ts": new ISODate()})'
WriteResult({ "nInserted" : 1 })
testrs:PRIMARY> 
bye
~$ mongodump <connection_args> -d test -c foo --out /tmp/dump
2019-07-21T10:13:54.137+0900	writing test.foo to 
2019-07-21T10:13:54.149+0900	done dumping test.foo (1 document)
~$ 
~$ bsondump /tmp/dump/test/foo.bson 
{"_id":7.0,"instr":"XYZ 3m","hval":904.72,"ts":{"$date":"2019-07-21T01:12:15.348Z"}}
~$ #bsondump's job is to print a JSON string representation. To make strictly
~$ #  valid JSON it must use only the base JSON scalar datatypes. To do this it
~$ #  follows MongoDB's "Extended JSON" rules such as using {"$date":"..."} for
~$ #  an ISODate. This makes it look like "ts" was a nested object, but it was
~$ #  scalar value - the BSON spec's 64-bit integer of UTC milliseconds.
~$ 
~$ od -An -t x1 /tmp/dump/test/foo.bson
 3e 00 00 00 01 5f 69 64 00 00 00 00 00 00 00 1c
 40 02 69 6e 73 74 72 00 07 00 00 00 58 59 5a 20
 33 6d 00 01 68 76 61 6c 00 f6 28 5c 8f c2 45 8c
 40 09 74 73 00 f4 1e 16 12 6c 01 00 00 00
~$ 
~$ #The 0x3e (= 62) little-endian int32 at the beginning is the byte length of
~$ #  the first doc. There is no size field/value for the whole collection at
~$ #  the beginning of the dump file.
```
{{% /expand %}}

Please see <a url="http://bsonspec.org/">bsonspec.org</a> if you want to know the full specification.

The main point for database users is:

- BSON is a variable-length format that packs the key-value pairs one after the other in tuples of <tt>type</tt> + <tt>key name</tt> \[+ <tt>byte length when not a fixed-length type</tt>\] + <tt>value data</tt>.
- Correct deserialization requires consuming the datatype value, the keyname, and a size field if the datatype uses one. Once you have that you can calculate the offset to the end of the value data.
- The start of BSON data is always assumed to be an object - never an array or scalar by itself. MongoDB won't store anything except a document in the collection structure.
  - mongodump's output \*.bson files likewise just start with a document. The next document begins in the byte immediately after the end of the previous. E.g. Imagine there is a mongodump-created file xyz.bson with ten's of thousands of documents, of size 25kb +/- 1kb. The first four bytes might be, say, the int32 value 26031. The 26031st byte will be a null byte. The 26032 ~ 26035th bytes will be the int32 value of the next document's byte size. Let's say it is 25938. The (26031 + 25938 =) 51969th byte will be final null byte of the second document. The next four bytes will be be size of the next document etc. As long as the dump is valid you can skip through the head to tail of the documents without parsing their content, til eventually there will be four bytes holding int32 value _n_, where _n_ is exactly the remaining length of the file starting from the beginning of this last object's int32 size field.
- For brevity no nested objects or arrays were shown in the example above, but they are also another key-value tuple in this serialization/deserialization algorithm. Type value 0x03 or 0x04 will indicate an (embedded) object or array respectively, then next four bytes will be an int32 for the total size (this size field and final null byte included).
- Arrays are packed just like objects, including having keys, but the spec insists the keys must be "0", "1", "2", ... etc. To be honest the keys seem totally superfluous to me.
- Key names consume space in _every_ document, even when all the documents in a collection have exactly the same ones. Use short key names to save space.
- Except for the required \["0", "1", "2", ...\] in arrays the format places no expectations/assumptions about which fields are included, or in which order they are serialized.

In practice BSON is the encoding of MongoDB and isn't used in any other software as popular as MongoDB yet. Nonetheless the BSON specification is one thing and MongoDB is another. There are some extra requirements that MongoDB places on any BSON object it will store:

- 16MB maximum size. The BSON specification places no upper limit on the size of data it encodes but the MongoDB database server and the drivers do.
- "\_id" field: Every document saved to a collection will have an "\_id" field value. It is the primary key value of all collections excluding the oplog. An \_id value of an ObjectId() type will be given automatically by the driver (not the db server) if none is specified at by the user code above the driver API beforean insert.

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
