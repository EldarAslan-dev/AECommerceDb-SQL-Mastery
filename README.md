# 🛒 NexusCommerce - Relational Database Design & T-SQL Mastery

![SQL Server](https://img.shields.io/badge/MS%20SQL%20Server-2022-red?style=flat&logo=microsoftsqlserver)
![T-SQL](https://img.shields.io/badge/Language-T--SQL-blue?style=flat)
![Architecture](https://img.shields.io/badge/Database%20Design-3NF%20Normalized-brightgreen)

A production-grade, highly normalized (3NF) relational database schema for an enterprise E-Commerce & Order Processing system built using MS SQL Server and T-SQL.

---

## 📐 Entity Relationship (ER) Schema Overview

```text
+-------------------+       +--------------------+       +-------------------+
|     Customers     |       |       Orders       |       |     Payments      |
+-------------------+       +--------------------+       +-------------------+
| PK  Id            |1     N| PK  Id             |1     1| PK  Id            |
|     FirstName     +-------< FK  CustomerId     +-------+ FK  OrderId       |
|     LastName      |       |     OrderDate      |       |     Amount        |
| UQ  Email         |       |     TotalAmount    |       |     PaymentMethod |
|     PhoneNumber   |       |     Status         |       |     PaymentStatus |
+-------------------+       +---------+----------+       +-------------------+
                                      | 1
                                      |
                                      | N
                            +---------+----------+
                            |     OrderItems     |
                            +--------------------+
                            | PK  Id             |
                            | FK  OrderId        |
                            | FK  ProductId      +-------+
                            |     Quantity       |       | N
                            |     UnitPrice      |       |
                            +--------------------+       |
                                                         | 1
                            +--------------------+       |
                            |      Products      |       |
                            +--------------------+       |
                            | PK  Id             +-------+
                            | FK  CategoryId     +-------+
                            | UQ  SKU            |       | N
                            |     Price          |       |
                            |     StockQuantity  |       |
                            +--------------------+       |
                                                         | 1
                            +--------------------+       |
                            |     Categories     |       |
                            +--------------------+       |
                            | PK  Id             +-------+
                            |     Name           |
                            | FK  ParentCatId    +---(Self Reference)
                            +--------------------+
