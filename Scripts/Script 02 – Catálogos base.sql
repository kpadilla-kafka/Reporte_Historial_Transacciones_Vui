USE [VUI_TransaccionesDB];
GO

/*==============================================================================
  Proyecto: Dashboard Gobernanza - Reporte 3
  Script: 02_Insertar_Catalogos_Base.sql
  Descripción:
      Inserta los catálogos base requeridos para el repositorio de transacciones VUI.

  Ambiente:
      Desarrollo

  Consideraciones:
      - No ejecutar en Producción.
      - Inserta datos solo si no existen.
      - Respeta catálogos indicados en la Solicitud de Cambio:
        Estados: Aprobado, Rechazado, Archivado.
        Solicitantes: Física, Jurídica, Ministerio.
      - Los bloques se insertan con base en los bloques utilizados en Gobernanza.
==============================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    /*===========================================================
      1. Catálogo: VUI_Estado
    ===========================================================*/
    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Estado WHERE Nombre = N'Aprobado')
        INSERT INTO dbo.VUI_Estado (Nombre) VALUES (N'Aprobado');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Estado WHERE Nombre = N'Rechazado')
        INSERT INTO dbo.VUI_Estado (Nombre) VALUES (N'Rechazado');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Estado WHERE Nombre = N'Archivado')
        INSERT INTO dbo.VUI_Estado (Nombre) VALUES (N'Archivado');


    /*===========================================================
      2. Catálogo: VUI_Solicitante
    ===========================================================*/
    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Solicitante WHERE Nombre = N'Física')
        INSERT INTO dbo.VUI_Solicitante (Nombre) VALUES (N'Física');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Solicitante WHERE Nombre = N'Jurídica')
        INSERT INTO dbo.VUI_Solicitante (Nombre) VALUES (N'Jurídica');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Solicitante WHERE Nombre = N'Ministerio')
        INSERT INTO dbo.VUI_Solicitante (Nombre) VALUES (N'Ministerio');


    /*===========================================================
      3. Catálogo: VUI_Bloque
    ===========================================================*/
    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Bloque WHERE Nombre = N'Trámites previos a Apertura de Empresa')
        INSERT INTO dbo.VUI_Bloque (Nombre) VALUES (N'Trámites previos a Apertura de Empresa');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Bloque WHERE Nombre = N'Trámites Zonas Francas')
        INSERT INTO dbo.VUI_Bloque (Nombre) VALUES (N'Trámites Zonas Francas');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Bloque WHERE Nombre = N'Trámites Atracción de Inversión')
        INSERT INTO dbo.VUI_Bloque (Nombre) VALUES (N'Trámites Atracción de Inversión');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Bloque WHERE Nombre = N'Trámites Ambientales')
        INSERT INTO dbo.VUI_Bloque (Nombre) VALUES (N'Trámites Ambientales');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Bloque WHERE Nombre = N'Trámites Institucionales')
        INSERT INTO dbo.VUI_Bloque (Nombre) VALUES (N'Trámites Institucionales');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Bloque WHERE Nombre = N'Trámites Registros')
        INSERT INTO dbo.VUI_Bloque (Nombre) VALUES (N'Trámites Registros');

    IF NOT EXISTS (SELECT 1 FROM dbo.VUI_Bloque WHERE Nombre = N'Trámites Construcción')
        INSERT INTO dbo.VUI_Bloque (Nombre) VALUES (N'Trámites Construcción');


    COMMIT TRANSACTION;

    SELECT 'ÉXITO: Catálogos base insertados o ya existentes correctamente.' AS Resultado;
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


/*===========================================================
  Validación rápida
===========================================================*/
SELECT * FROM dbo.VUI_Estado ORDER BY VUI_Estado;
SELECT * FROM dbo.VUI_Solicitante ORDER BY VUI_Solicitante;
SELECT * FROM dbo.VUI_Bloque ORDER BY VUI_Bloque;
