-- ============================================================================
-- Layihə: AECommerceDb - Relational Database Design & T-SQL Mastery
-- ============================================================================

-- 1. BAZANIN YARADILMASI
CREATE DATABASE AECommerceDb;
GO

USE AECommerceDb;
GO

-- 2. CƏDVƏLLƏR (TABLES & CONSTRAINTS)

-- Müştərilər
CREATE TABLE Customers (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(20) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- Kateqoriyalar (Self-Referencing İyerarxiya)
CREATE TABLE Categories (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(250) NULL,
    ParentCategoryId INT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    CONSTRAINT FK_Categories_ParentCategory 
        FOREIGN KEY (ParentCategoryId) REFERENCES Categories(Id)
);
GO

-- Məhsullar
CREATE TABLE Products (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CategoryId INT NOT NULL,
    Name NVARCHAR(150) NOT NULL,
    SKU VARCHAR(50) NOT NULL UNIQUE,
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Products_Categories 
        FOREIGN KEY (CategoryId) REFERENCES Categories(Id),
    CONSTRAINT CK_Products_Price 
        CHECK (Price > 0),
    CONSTRAINT CK_Products_StockQuantity 
        CHECK (StockQuantity >= 0)
);
GO

-- Sifarişlər
CREATE TABLE Orders (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    TotalAmount DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    ShippingAddress NVARCHAR(300) NOT NULL,

    CONSTRAINT FK_Orders_Customers 
        FOREIGN KEY (CustomerId) REFERENCES Customers(Id),
    CONSTRAINT CK_Orders_TotalAmount 
        CHECK (TotalAmount >= 0),
    CONSTRAINT CK_Orders_Status 
        CHECK (Status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'))
);
GO

-- Sifariş Detalları (Many-to-Many Bridge Table)
CREATE TABLE OrderItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18, 2) NOT NULL,

    CONSTRAINT FK_OrderItems_Orders 
        FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Products 
        FOREIGN KEY (ProductId) REFERENCES Products(Id),
    CONSTRAINT CK_OrderItems_Quantity 
        CHECK (Quantity > 0),
    CONSTRAINT CK_OrderItems_UnitPrice 
        CHECK (UnitPrice > 0),
    CONSTRAINT UQ_OrderItems_Order_Product 
        UNIQUE (OrderId, ProductId)
);
GO

-- Ödənişlər
CREATE TABLE Payments (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL UNIQUE,
    PaymentDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Amount DECIMAL(18, 2) NOT NULL,
    PaymentMethod NVARCHAR(30) NOT NULL,
    PaymentStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    TransactionCode VARCHAR(100) NULL,

    CONSTRAINT FK_Payments_Orders 
        FOREIGN KEY (OrderId) REFERENCES Orders(Id),
    CONSTRAINT CK_Payments_Amount 
        CHECK (Amount > 0),
    CONSTRAINT CK_Payments_PaymentMethod 
        CHECK (PaymentMethod IN ('CreditCard', 'DebitCard', 'CashOnDelivery', 'BankTransfer')),
    CONSTRAINT CK_Payments_Status 
        CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded'))
);
GO

-- 3. TEST MƏLUMATLARI (MOCK SEED DATA)

INSERT INTO Categories (Name, Description, ParentCategoryId)
VALUES 
    (N'Elektronika', N'Bütün elektron cihazlar və avadanlıqlar', NULL),
    (N'Geyim', N'Kişi və qadın geyimləri', NULL),
    (N'Smartfonlar', N'Mobil telefonlar', 1),
    (N'Noutbuklar', N'Portativ kompüterlər', 1);

INSERT INTO Customers (FirstName, LastName, Email, PhoneNumber)
VALUES 
    (N'Əli', N'Məmmədov', 'ali.mammadov@example.com', '+994501112233'),
    (N'Aygün', N'Həsənova', 'aygun.hasanova@example.com', '+994552223344'),
    (N'Rəşad', N'Quliyev', 'rashad.guliyev@example.com', '+994703334455');

INSERT INTO Products (CategoryId, Name, SKU, Price, StockQuantity)
VALUES 
    (3, N'iPhone 15 Pro', 'IPHONE-15P-128', 2399.00, 15),
    (3, N'Samsung Galaxy S24', 'SAMS-S24-256', 1899.00, 20),
    (4, N'MacBook Pro 14 M3', 'APPL-MBP14-M3', 3599.00, 8),
    (4, N'Dell XPS 13', 'DELL-XPS13-512', 2450.00, 5);

INSERT INTO Orders (CustomerId, TotalAmount, Status, ShippingAddress)
VALUES 
    (1, 4298.00, 'Processing', N'Bakı ş., Nərimanov r., Həsən Əliyev k. 45'),
    (2, 3599.00, 'Shipped', N'Bakı ş., Yasamal r., İnşaatçılar pr. 12');

INSERT INTO OrderItems (OrderId, ProductId, Quantity, UnitPrice)
VALUES 
    (1, 1, 1, 2399.00),
    (1, 2, 1, 1899.00),
    (2, 3, 1, 3599.00);

INSERT INTO Payments (OrderId, Amount, PaymentMethod, PaymentStatus, TransactionCode)
VALUES 
    (1, 4298.00, 'CreditCard', 'Completed', 'TXN-98472918'),
    (2, 3599.00, 'DebitCard', 'Completed', 'TXN-11928374');
GO

-- 4. BİZNES MƏNTİQİ: TRİQGERLƏR VƏ PROSEDURLAR

-- Avtomatik stok azaldıcı Trigger
CREATE OR ALTER TRIGGER TR_OrderItems_ReduceStock
ON OrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Products p
        INNER JOIN inserted i ON p.Id = i.ProductId
        WHERE p.StockQuantity < i.Quantity
    )
    BEGIN
        RAISERROR (N'Anbarda kifayət qədər məhsul yoxdur! Əməliyyat ləğv edildi.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE p
    SET p.StockQuantity = p.StockQuantity - i.Quantity
    FROM Products p
    INNER JOIN inserted i ON p.Id = i.ProductId;
END;
GO

-- Tranzaksiyalı Sifariş Yaratma Proseduru
CREATE OR ALTER PROCEDURE sp_CreateOrderWithItem
    @CustomerId INT,
    @ProductId INT,
    @Quantity INT,
    @ShippingAddress NVARCHAR(300),
    @NewOrderId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UnitPrice DECIMAL(18, 2);
        DECLARE @AvailableStock INT;

        SELECT 
            @UnitPrice = Price,
            @AvailableStock = StockQuantity
        FROM Products
        WHERE Id = @ProductId AND IsActive = 1;

        IF @UnitPrice IS NULL
            THROW 50001, N'Məhsul tapılmadı və ya aktiv deyil.', 1;

        IF @AvailableStock < @Quantity
            THROW 50002, N'Tələb olunan say qədər stok mövcud deyil.', 1;

        DECLARE @TotalAmount DECIMAL(18, 2) = @UnitPrice * @Quantity;

        INSERT INTO Orders (CustomerId, TotalAmount, Status, ShippingAddress)
        VALUES (@CustomerId, @TotalAmount, 'Processing', @ShippingAddress);

        SET @NewOrderId = SCOPE_IDENTITY();

        INSERT INTO OrderItems (OrderId, ProductId, Quantity, UnitPrice)
        VALUES (@NewOrderId, @ProductId, @Quantity, @UnitPrice);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

-- 5. PERFORMANS İNDEKSLƏRİ (INDEXING)

CREATE NONCLUSTERED INDEX IX_Orders_OrderDate_Status
ON Orders (OrderDate DESC, Status);
GO

CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
ON Orders (CustomerId);
GO

CREATE NONCLUSTERED INDEX IX_Products_CategoryId_IsActive
ON Products (CategoryId, IsActive)
INCLUDE (Name, Price);
GO

-- 6. ANALİTİK REPORT SORĞULARI

-- Report 1: Ətraflı sifariş çıxarışı
SELECT 
    o.Id AS OrderId,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
    c.Email,
    p.Name AS ProductName,
    cat.Name AS CategoryName,
    oi.Quantity,
    oi.UnitPrice,
    (oi.Quantity * oi.UnitPrice) AS LineTotal,
    o.Status AS OrderStatus,
    o.OrderDate
FROM Orders o
INNER JOIN Customers c ON o.CustomerId = c.Id
INNER JOIN OrderItems oi ON o.Id = oi.OrderId
INNER JOIN Products p ON oi.ProductId = p.Id
INNER JOIN Categories cat ON p.CategoryId = cat.Id
ORDER BY o.OrderDate DESC;

-- Report 2: Müştəri dövriyyəsi
SELECT 
    c.Id AS CustomerId,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
    c.Email,
    COUNT(o.Id) AS TotalOrdersCount,
    ISNULL(SUM(o.TotalAmount), 0.00) AS LifetimeSpend
FROM Customers c
LEFT JOIN Orders o ON c.Id = o.CustomerId
GROUP BY c.Id, c.FirstName, c.LastName, c.Email
ORDER BY LifetimeSpend DESC;

-- Report 3: Kateqoriya gəlirləri
SELECT 
    cat.Name AS CategoryName,
    SUM(oi.Quantity) AS TotalUnitsSold,
    SUM(oi.Quantity * oi.UnitPrice) AS TotalRevenue
FROM Categories cat
INNER JOIN Products p ON cat.Id = p.CategoryId
INNER JOIN OrderItems oi ON p.Id = oi.ProductId
GROUP BY cat.Name
ORDER BY TotalRevenue DESC;
GO