const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Records", function () {
  let Records, records, owner, addr1, addr2;

  beforeEach(async function () {
    Records = await ethers.getContractFactory("Records");
    [owner, addr1, addr2] = await ethers.getSigners();
    records = await Records.deploy();
    await records.deployed();
  });

  it("Should add a record", async function () {
    const record = {
      name: "Alice",
      age: 28,
      dataHash: "Qm123",
      description: "First record",
      timestamp: 0,
    };
    await records.addRecord(record);
    const result = await records.getRecord(owner.address);
    expect(result.name).to.equal("Alice");
  });

  it("Should prevent duplicate records", async function () {
    const record = {
      name: "Alice",
      age: 28,
      dataHash: "Qm123",
      description: "First record",
      timestamp: 0,
    };
    await records.addRecord(record);
    await expect(records.addRecord(record)).to.be.revertedWith(
      "Record already exists for this address"
    );
  });

  it("Should fetch record by address", async function () {
    const record = {
      name: "Bob",
      age: 35,
      dataHash: "Qm456",
      description: "Second record",
      timestamp: 0,
    };
    await records.connect(addr1).addRecord(record);
    const result = await records.getRecord(addr1.address);
    expect(result.name).to.equal("Bob");
  });

  it("Should fetch all records", async function () {
    await records.addRecord({
      name: "Alice",
      age: 28,
      dataHash: "Qm123",
      description: "First record",
      timestamp: 0,
    });
    await records.connect(addr1).addRecord({
      name: "Bob",
      age: 35,
      dataHash: "Qm456",
      description: "Second record",
      timestamp: 0,
    });
    const allRecords = await records.fetchRecords();
    expect(allRecords.length).to.equal(2);
  });

  it("Should only allow users with records to call fetchRecord()", async function () {
    const record = {
      name: "Charlie",
      age: 30,
      dataHash: "Qm789",
      description: "Third record",
      timestamp: 0,
    };
    await records.connect(addr2).addRecord(record);
    const myRecord = await records.connect(addr2).fetchRecord();
    expect(myRecord.name).to.equal("Charlie");
    await expect(records.connect(addr1).fetchRecord()).to.be.revertedWith(
      "You must have added a record"
    );
  });
});
