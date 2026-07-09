USE [VUI_TransaccionesDB];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.VUI_Bloque 
        WHERE Nombre = N'Trámites Apertura de Empresa'
    )
    BEGIN
        INSERT INTO dbo.VUI_Bloque (Nombre)
        VALUES (N'Trámites Apertura de Empresa');
    END;

    COMMIT TRANSACTION;

    SELECT 'ÉXITO: Bloque faltante insertado o ya existente correctamente.' AS Resultado;
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

SELECT *
FROM dbo.VUI_Bloque
ORDER BY VUI_Bloque;
