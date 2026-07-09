USE [VUI_TransaccionesDB];
GO

/*==============================================================================
  Proyecto: Dashboard Gobernanza - Reporte 3
  Script: 01_Crear_Estructura_Base.sql
  Descripción:
      Crea las tablas base para el repositorio de transacciones VUI.

  Ambiente:
      Desarrollo

  Consideraciones:
      - La base de datos ya debe existir.
      - No ejecutar en Producción.
      - Las tablas se crean solo si no existen.
      - Se utilizan PK BIGINT IDENTITY.
      - Se utilizan FK para integridad referencial.
      - Se incluye Activo BIT para borrado lógico.
==============================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    /*===========================================================
      1. Catálogo de bloques
    ===========================================================*/
    IF OBJECT_ID('dbo.VUI_Bloque', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.VUI_Bloque
        (
            VUI_Bloque BIGINT IDENTITY(1,1) NOT NULL,
            Nombre NVARCHAR(255) NOT NULL,
            Activo BIT NOT NULL CONSTRAINT DF_VUI_Bloque_Activo DEFAULT (1),

            CONSTRAINT PK_VUI_Bloque
                PRIMARY KEY CLUSTERED (VUI_Bloque)
        );
    END;

    /*===========================================================
      2. Catálogo de estados
    ===========================================================*/
    IF OBJECT_ID('dbo.VUI_Estado', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.VUI_Estado
        (
            VUI_Estado BIGINT IDENTITY(1,1) NOT NULL,
            Nombre NVARCHAR(100) NOT NULL,
            Activo BIT NOT NULL CONSTRAINT DF_VUI_Estado_Activo DEFAULT (1),

            CONSTRAINT PK_VUI_Estado
                PRIMARY KEY CLUSTERED (VUI_Estado)
        );
    END;

    /*===========================================================
      3. Catálogo de solicitantes
    ===========================================================*/
    IF OBJECT_ID('dbo.VUI_Solicitante', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.VUI_Solicitante
        (
            VUI_Solicitante BIGINT IDENTITY(1,1) NOT NULL,
            Nombre NVARCHAR(100) NOT NULL,
            Activo BIT NOT NULL CONSTRAINT DF_VUI_Solicitante_Activo DEFAULT (1),

            CONSTRAINT PK_VUI_Solicitante
                PRIMARY KEY CLUSTERED (VUI_Solicitante)
        );
    END;

    /*===========================================================
      4. Catálogo de trámites
    ===========================================================*/
    IF OBJECT_ID('dbo.VUI_Tramite', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.VUI_Tramite
        (
            VUI_Tramite BIGINT IDENTITY(1,1) NOT NULL,
            VUI_Bloque BIGINT NOT NULL,
            Nombre NVARCHAR(255) NOT NULL,
            Activo BIT NOT NULL CONSTRAINT DF_VUI_Tramite_Activo DEFAULT (1),
            FechaHabilitacion DATE NULL,

            CONSTRAINT PK_VUI_Tramite
                PRIMARY KEY CLUSTERED (VUI_Tramite),

            CONSTRAINT FK_VUI_Tramite_VUI_Bloque
                FOREIGN KEY (VUI_Bloque)
                REFERENCES dbo.VUI_Bloque (VUI_Bloque)
        );
    END;

    /*===========================================================
      5. Tabla transaccional principal
    ===========================================================*/
    IF OBJECT_ID('dbo.VUI_Transaccion', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.VUI_Transaccion
        (
            VUI_Transaccion BIGINT IDENTITY(1,1) NOT NULL,
            VUI_Tramite BIGINT NOT NULL,
            VUI_Estado BIGINT NOT NULL,
            VUI_Solicitante BIGINT NULL,
            Referencia NVARCHAR(255) NOT NULL,
            FechaTransaccion DATETIME NOT NULL,
            Activo BIT NOT NULL CONSTRAINT DF_VUI_Transaccion_Activo DEFAULT (1),

            CONSTRAINT PK_VUI_Transaccion
                PRIMARY KEY CLUSTERED (VUI_Transaccion),

            CONSTRAINT FK_VUI_Transaccion_VUI_Tramite
                FOREIGN KEY (VUI_Tramite)
                REFERENCES dbo.VUI_Tramite (VUI_Tramite),

            CONSTRAINT FK_VUI_Transaccion_VUI_Estado
                FOREIGN KEY (VUI_Estado)
                REFERENCES dbo.VUI_Estado (VUI_Estado),

            CONSTRAINT FK_VUI_Transaccion_VUI_Solicitante
                FOREIGN KEY (VUI_Solicitante)
                REFERENCES dbo.VUI_Solicitante (VUI_Solicitante)
        );
    END;

    /*===========================================================
      6. Tabla específica MINSA
    ===========================================================*/
    IF OBJECT_ID('dbo.VUI_MINSA', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.VUI_MINSA
        (
            VUI_MINSA BIGINT IDENTITY(1,1) NOT NULL,
            VUI_Transaccion BIGINT NOT NULL,
            Activo BIT NOT NULL CONSTRAINT DF_VUI_MINSA_Activo DEFAULT (1),

            CONSTRAINT PK_VUI_MINSA
                PRIMARY KEY CLUSTERED (VUI_MINSA),

            CONSTRAINT FK_VUI_MINSA_VUI_Transaccion
                FOREIGN KEY (VUI_Transaccion)
                REFERENCES dbo.VUI_Transaccion (VUI_Transaccion)
        );
    END;

    COMMIT TRANSACTION;

    SELECT 'ÉXITO: La estructura base fue creada o ya existía correctamente.' AS Resultado;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS ErrorNumero,
        ERROR_MESSAGE() AS ErrorMensaje,
        'ABORTO SEGURO: No se consolidaron cambios incompletos.' AS Estado;
END CATCH;
GO
