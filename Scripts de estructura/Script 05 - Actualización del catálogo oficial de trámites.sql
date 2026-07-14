USE [VUI_TransaccionesDB];
GO

/*==============================================================================
  Proyecto: Dashboard Gobernanza - Reporte 3
  Script: 05_Actualizar_Catalogo_Oficial_Tramites.sql

  Descripción:
      Actualiza el catálogo de trámites de la Ventanilla Única de Inversión
      conforme a la estructura utilizada en el Reporte 1.

      El script:
        - Conserva los identificadores existentes de los trámites.
        - Corrige los nombres abreviados o genéricos.
        - Actualiza el orden de presentación de cada trámite.
        - Inserta los trámites faltantes.
        - Reactiva los registros que pertenezcan al catálogo oficial.
        - Desactiva mediante borrado lógico los registros no contemplados.
        - Evita duplicar datos al ejecutarse nuevamente.
        - Valida la cantidad esperada de trámites por bloque.

  Ambiente:
      Desarrollo

  Cantidades esperadas:
      1. Trámites previos a Apertura de Empresa: 14
      2. Trámites Apertura de Empresa:           20
      3. Trámites Zonas Francas:                  4
      4. Trámites Atracción de Inversión:         1
      5. Trámites Ambientales:                   19
      6. Trámites Institucionales:                5
      7. Trámites Registros:                      4
      8. Trámites Construcción:                   4

      Total esperado: 71 trámites activos.

  Consideraciones:
      - Ejecutar únicamente en el ambiente de Desarrollo.
      - No elimina físicamente registros.
      - Mantiene las fechas de habilitación existentes.
      - Los trámites nuevos se insertan con FechaHabilitacion = NULL.
      - La relación del catálogo se determina mediante Bloque + OrdenTramite.
      - El script utiliza una transacción y realiza rollback ante cualquier error.

  Historial de cambios:
  ------------------------------------------------------------------------------
  Fecha        Autor               Descripción
  ----------  ------------------  -----------------------------------------------
  2026-07-10  Katiana Padilla     Creación del catálogo oficial completo.
  ------------------------------------------------------------------------------
==============================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    /*==========================================================================
      1. Validaciones preliminares
    ==========================================================================*/

    IF OBJECT_ID(N'dbo.VUI_Bloque', N'U') IS NULL
        THROW 50001, 'No existe la tabla dbo.VUI_Bloque.', 1;

    IF OBJECT_ID(N'dbo.VUI_Tramite', N'U') IS NULL
        THROW 50002, 'No existe la tabla dbo.VUI_Tramite.', 1;

    IF COL_LENGTH(N'dbo.VUI_Bloque', N'OrdenBloque') IS NULL
        THROW 50003, 'La tabla dbo.VUI_Bloque no contiene OrdenBloque.', 1;

    IF COL_LENGTH(N'dbo.VUI_Tramite', N'OrdenTramite') IS NULL
        THROW 50004, 'La tabla dbo.VUI_Tramite no contiene OrdenTramite.', 1;

    IF
    (
        SELECT COUNT(*)
        FROM dbo.VUI_Bloque
        WHERE Activo = 1
          AND OrdenBloque BETWEEN 1 AND 8
    ) <> 8
    BEGIN
        THROW 50005,
              'No se encontraron los 8 bloques activos requeridos.',
              1;
    END;


    /*==========================================================================
      2. Creación del catálogo oficial temporal
    ==========================================================================*/

    CREATE TABLE #CatalogoOficial
    (
        OrdenBloque  INT            NOT NULL,
        Bloque       NVARCHAR(255)  NOT NULL,
        OrdenTramite INT            NOT NULL,
        Tramite      NVARCHAR(255)  NOT NULL,

        CONSTRAINT PK_CatalogoOficial
            PRIMARY KEY (OrdenBloque, OrdenTramite)
    );


    /*==========================================================================
      3. Carga del catálogo oficial
    ==========================================================================*/

    INSERT INTO #CatalogoOficial
    (
        OrdenBloque,
        Bloque,
        OrdenTramite,
        Tramite
    )
    VALUES

    /*--------------------------------------------------------------------------
      Bloque 1: Trámites previos a Apertura de Empresa
    --------------------------------------------------------------------------*/
    (1, N'Trámites previos a Apertura de Empresa', 1,
        N'Calderas (Versión 1)'),

    (1, N'Trámites previos a Apertura de Empresa', 2,
        N'Calderas Operación'),

    (1, N'Trámites previos a Apertura de Empresa', 3,
        N'Calderas Instalación'),

    (1, N'Trámites previos a Apertura de Empresa', 4,
        N'Calderas Inspección Anual'),

    (1, N'Trámites previos a Apertura de Empresa', 5,
        N'Calderas Renovación'),

    (1, N'Trámites previos a Apertura de Empresa', 6,
        N'Calderas Modificación'),

    (1, N'Trámites previos a Apertura de Empresa', 7,
        N'Calderas Cancelación'),

    (1, N'Trámites previos a Apertura de Empresa', 8,
        N'Sistema de Tratamiento de Aguas Residuales'),

    (1, N'Trámites previos a Apertura de Empresa', 9,
        N'Sistema de Tratamiento de Aguas Residuales Renovación'),

    (1, N'Trámites previos a Apertura de Empresa', 10,
        N'Sistema de Tratamiento de Aguas Residuales Modificación'),

    (1, N'Trámites previos a Apertura de Empresa', 11,
        N'Tanques de Autoconsumo'),

    (1, N'Trámites previos a Apertura de Empresa', 12,
        N'Tanques de Autoconsumo Renovación'),

    (1, N'Trámites previos a Apertura de Empresa', 13,
        N'Tanques de Autoconsumo Modificación'),

    (1, N'Trámites previos a Apertura de Empresa', 14,
        N'Tanques de Autoconsumo Cancelación'),


    /*--------------------------------------------------------------------------
      Bloque 2: Trámites Apertura de Empresa
    --------------------------------------------------------------------------*/
    (2, N'Trámites Apertura de Empresa', 1,
        N'Certificado Veterinario de Operación (CVO)'),

    (2, N'Trámites Apertura de Empresa', 2,
        N'Patente Comercial'),

    (2, N'Trámites Apertura de Empresa', 3,
        N'Patente Comercial Cambio de Ubicación'),

    (2, N'Trámites Apertura de Empresa', 4,
        N'Patente Comercial Cambio de Actividad'),

    (2, N'Trámites Apertura de Empresa', 5,
        N'Licencia de Licores'),

    (2, N'Trámites Apertura de Empresa', 6,
        N'Permiso Sanitario de Funcionamiento'),

    (2, N'Trámites Apertura de Empresa', 7,
        N'Permiso Sanitario de Funcionamiento Renovación'),

    (2, N'Trámites Apertura de Empresa', 8,
        N'Permiso Sanitario de Funcionamiento Modificación'),

    (2, N'Trámites Apertura de Empresa', 9,
        N'Permiso Sanitario de Funcionamiento Cancelación'),

    (2, N'Trámites Apertura de Empresa', 10,
        N'Permiso de Habilitación'),

    (2, N'Trámites Apertura de Empresa', 11,
        N'Permiso de Habilitación Renovación'),

    (2, N'Trámites Apertura de Empresa', 12,
        N'Permiso de Habilitación Modificación'),

    (2, N'Trámites Apertura de Empresa', 13,
        N'Permiso de Habilitación Cancelación'),

    (2, N'Trámites Apertura de Empresa', 14,
        N'Registro de Gestor de Residuos'),

    (2, N'Trámites Apertura de Empresa', 15,
        N'Renovación del Registro de Gestor de Residuos'),

    (2, N'Trámites Apertura de Empresa', 16,
        N'Modificación al Registro de Gestor de Residuos'),

    (2, N'Trámites Apertura de Empresa', 17,
        N'Registro de Gestor de Residuos por primera vez con un PSF vigente en físico'),

    (2, N'Trámites Apertura de Empresa', 18,
        N'Renovación del Registro de Gestor de Residuos con un PSF vigente en físico'),

    (2, N'Trámites Apertura de Empresa', 19,
        N'Modificación del Registro de Gestor de Residuos con un PSF vigente en físico'),

    (2, N'Trámites Apertura de Empresa', 20,
        N'Reporte de Gestión Integral de Residuos'),


    /*--------------------------------------------------------------------------
      Bloque 3: Trámites Zonas Francas
    --------------------------------------------------------------------------*/
    (3, N'Trámites Zonas Francas', 1,
        N'Solicitud de Ingreso al Régimen de Zonas Francas'),

    (3, N'Trámites Zonas Francas', 2,
        N'Solicitud de Ingreso al Régimen de Zonas Francas - 20 Bis'),

    (3, N'Trámites Zonas Francas', 3,
        N'Solicitud de Estancias Categoría A: Empresas bajo el Régimen de Zona Franca'),

    (3, N'Trámites Zonas Francas', 4,
        N'Solicitud de Ejecutivos Categoría A: Empresas bajo el Régimen de Zona Franca'),


    /*--------------------------------------------------------------------------
      Bloque 4: Trámites Atracción de Inversión
    --------------------------------------------------------------------------*/
    (4, N'Trámites Atracción de Inversión', 1,
        N'Proyecto de Inversión Fílmica y Audiovisual'),


    /*--------------------------------------------------------------------------
      Bloque 5: Trámites Ambientales
    --------------------------------------------------------------------------*/
    (5, N'Trámites Ambientales', 1,
        N'Permiso de vertido'),

    (5, N'Trámites Ambientales', 2,
        N'Permiso de perforación de pozos'),

    (5, N'Trámites Ambientales', 3,
        N'Concesión de aguas subterráneas'),

    (5, N'Trámites Ambientales', 4,
        N'Concesión de aguas superficiales'),

    (5, N'Trámites Ambientales', 5,
        N'Presentación de Proyecto para Estaciones de Servicio'),

    (5, N'Trámites Ambientales', 6,
        N'D1'),

    (5, N'Trámites Ambientales', 7,
        N'D1 - Torres'),

    (5, N'Trámites Ambientales', 8,
        N'D1 - C'),

    (5, N'Trámites Ambientales', 9,
        N'D1 - Desalinización con Declaración Jurada'),

    (5, N'Trámites Ambientales', 10,
        N'D1 - Desalinización con Pronóstico-Plan de Gestión Ambiental'),

    (5, N'Trámites Ambientales', 11,
        N'D1 - Desalinización con Estudio de Impacto Ambiental'),

    (5, N'Trámites Ambientales', 12,
        N'D4 - Forestal'),

    (5, N'Trámites Ambientales', 13,
        N'D6 - Cuadrante Urbano'),

    (5, N'Trámites Ambientales', 14,
        N'EDA - Estudio de Diagnóstico Ambiental'),

    (5, N'Trámites Ambientales', 15,
        N'SDA - Solicitud Devolución Garantía con Resolución de Archivo de Expediente'),

    (5, N'Trámites Ambientales', 16,
        N'SDC - Solicitud de Devolución Garantía Cierre Técnico'),

    (5, N'Trámites Ambientales', 17,
        N'RGA - Solicitud de Renovación de Garantía Ambiental'),

    (5, N'Trámites Ambientales', 18,
        N'CRG - Presentación Comprobante Renovación Garantía'),

    (5, N'Trámites Ambientales', 19,
        N'DDE - Devolución de Depósitos Erróneos'),


    /*--------------------------------------------------------------------------
      Bloque 6: Trámites Institucionales
    --------------------------------------------------------------------------*/
    (6, N'Trámites Institucionales', 1,
        N'Emisión de Criterios Técnicos sobre Humedales'),

    (6, N'Trámites Institucionales', 2,
        N'Firmas Declaraciones Juradas'),

    (6, N'Trámites Institucionales', 3,
        N'Gestión de Aprobaciones'),

    (6, N'Trámites Institucionales', 4,
        N'Inspecciones AFPA'),

    (6, N'Trámites Institucionales', 5,
        N'Planes Reguladores'),


    /*--------------------------------------------------------------------------
      Bloque 7: Trámites Registros
    --------------------------------------------------------------------------*/
    (7, N'Trámites Registros', 1,
        N'Registro IAGT (Data Completa)'),

    (7, N'Trámites Registros', 2,
        N'Licencias de Cannabis para uso medicinal y terapéutico'),

    (7, N'Trámites Registros', 3,
        N'Autorizaciones de Cáñamo para uso alimentario e industrial'),

    (7, N'Trámites Registros', 4,
        N'Fichas de Emergencia para el Transporte Terrestre de Mercancías Peligrosas'),


    /*--------------------------------------------------------------------------
      Bloque 8: Trámites Construcción
    --------------------------------------------------------------------------*/
    (8, N'Trámites Construcción', 1,
        N'APC - Administrador de Proyectos de Construcción'),

    (8, N'Trámites Construcción', 2,
        N'APC-M - Administrador de Proyectos de Construcción – Municipal'),

    (8, N'Trámites Construcción', 3,
        N'APC-R - Administrador de Proyectos de Construcción – Requisitos'),

    (8, N'Trámites Construcción', 4,
        N'APT - Administrador de Proyectos de Topografía');


    /*==========================================================================
      4. Validar que el catálogo temporal tenga exactamente 71 registros
    ==========================================================================*/

    IF (SELECT COUNT(*) FROM #CatalogoOficial) <> 71
    BEGIN
        THROW 50006,
              'El catálogo temporal no contiene los 71 trámites esperados.',
              1;
    END;


    /*==========================================================================
      5. Validar posibles duplicados existentes por Bloque + OrdenTramite
    ==========================================================================*/

    IF EXISTS
    (
        SELECT
            T.VUI_Bloque,
            T.OrdenTramite
        FROM dbo.VUI_Tramite T
        WHERE T.OrdenTramite IS NOT NULL
        GROUP BY
            T.VUI_Bloque,
            T.OrdenTramite
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50007,
              'Existen trámites duplicados por bloque y orden. Revise el catálogo antes de continuar.',
              1;
    END;


    /*==========================================================================
      6. Actualizar trámites existentes

         Se conserva VUI_Tramite para no afectar las llaves foráneas ni los
         datos dummy existentes en dbo.VUI_Transaccion.
    ==========================================================================*/

    UPDATE T
    SET
        T.Nombre = C.Tramite,
        T.OrdenTramite = C.OrdenTramite,
        T.Activo = 1
    FROM dbo.VUI_Tramite T
    INNER JOIN dbo.VUI_Bloque B
        ON B.VUI_Bloque = T.VUI_Bloque
    INNER JOIN #CatalogoOficial C
        ON C.OrdenBloque = B.OrdenBloque
       AND C.OrdenTramite = T.OrdenTramite;


    /*==========================================================================
      7. Insertar trámites faltantes
    ==========================================================================*/

    INSERT INTO dbo.VUI_Tramite
    (
        VUI_Bloque,
        Nombre,
        Activo,
        FechaHabilitacion,
        OrdenTramite
    )
    SELECT
        B.VUI_Bloque,
        C.Tramite,
        1,
        NULL,
        C.OrdenTramite
    FROM #CatalogoOficial C
    INNER JOIN dbo.VUI_Bloque B
        ON B.OrdenBloque = C.OrdenBloque
       AND B.Nombre = C.Bloque
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.VUI_Tramite T
        WHERE T.VUI_Bloque = B.VUI_Bloque
          AND T.OrdenTramite = C.OrdenTramite
    );


    /*==========================================================================
      8. Desactivar registros que no pertenezcan al catálogo oficial

         No se eliminan físicamente porque podrían estar relacionados con
         transacciones existentes.
    ==========================================================================*/

    UPDATE T
    SET T.Activo = 0
    FROM dbo.VUI_Tramite T
    INNER JOIN dbo.VUI_Bloque B
        ON B.VUI_Bloque = T.VUI_Bloque
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM #CatalogoOficial C
        WHERE C.OrdenBloque = B.OrdenBloque
          AND C.OrdenTramite = T.OrdenTramite
    );


    /*==========================================================================
      9. Validar resultado antes del COMMIT
    ==========================================================================*/

    IF
    (
        SELECT COUNT(*)
        FROM dbo.VUI_Tramite
        WHERE Activo = 1
    ) <> 71
    BEGIN
        THROW 50008,
              'La cantidad final de trámites activos no corresponde a 71.',
              1;
    END;

    IF EXISTS
    (
        SELECT
            C.OrdenBloque,
            C.OrdenTramite
        FROM #CatalogoOficial C
        INNER JOIN dbo.VUI_Bloque B
            ON B.OrdenBloque = C.OrdenBloque
           AND B.Nombre = C.Bloque
        LEFT JOIN dbo.VUI_Tramite T
            ON T.VUI_Bloque = B.VUI_Bloque
           AND T.OrdenTramite = C.OrdenTramite
           AND T.Nombre = C.Tramite
           AND T.Activo = 1
        WHERE T.VUI_Tramite IS NULL
    )
    BEGIN
        THROW 50009,
              'Uno o más trámites oficiales no fueron insertados o actualizados correctamente.',
              1;
    END;

    DROP TABLE #CatalogoOficial;

    COMMIT TRANSACTION;

    SELECT
        N'ÉXITO: El catálogo oficial fue actualizado correctamente.' AS Resultado,
        71 AS TotalTramitesActivos;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    IF OBJECT_ID(N'tempdb..#CatalogoOficial') IS NOT NULL
        DROP TABLE #CatalogoOficial;

    SELECT
        ERROR_NUMBER() AS ErrorNumero,
        ERROR_LINE() AS ErrorLinea,
        ERROR_MESSAGE() AS ErrorMensaje,
        N'ABORTO SEGURO: No se consolidaron cambios incompletos.' AS Estado;
END CATCH;
GO


/*==============================================================================
  10. Validación final por bloque
==============================================================================*/

SELECT
    B.OrdenBloque,
    B.Nombre AS Bloque,
    COUNT(T.VUI_Tramite) AS CantidadTramitesActivos,
    CASE B.OrdenBloque
        WHEN 1 THEN 14
        WHEN 2 THEN 20
        WHEN 3 THEN 4
        WHEN 4 THEN 1
        WHEN 5 THEN 19
        WHEN 6 THEN 5
        WHEN 7 THEN 4
        WHEN 8 THEN 4
    END AS CantidadEsperada,
    CASE
        WHEN COUNT(T.VUI_Tramite) =
             CASE B.OrdenBloque
                 WHEN 1 THEN 14
                 WHEN 2 THEN 20
                 WHEN 3 THEN 4
                 WHEN 4 THEN 1
                 WHEN 5 THEN 19
                 WHEN 6 THEN 5
                 WHEN 7 THEN 4
                 WHEN 8 THEN 4
             END
            THEN N'CORRECTO'
        ELSE N'REVISAR'
    END AS Validacion
FROM dbo.VUI_Bloque B
LEFT JOIN dbo.VUI_Tramite T
    ON T.VUI_Bloque = B.VUI_Bloque
   AND T.Activo = 1
WHERE B.Activo = 1
GROUP BY
    B.OrdenBloque,
    B.Nombre
ORDER BY
    B.OrdenBloque;
GO


/*==============================================================================
  11. Detalle final del catálogo
==============================================================================*/

SELECT
    B.OrdenBloque,
    B.Nombre AS Bloque,
    T.OrdenTramite,
    T.VUI_Tramite,
    T.Nombre AS Tramite,
    T.FechaHabilitacion,
    T.Activo
FROM dbo.VUI_Bloque B
INNER JOIN dbo.VUI_Tramite T
    ON T.VUI_Bloque = B.VUI_Bloque
WHERE B.Activo = 1
  AND T.Activo = 1
ORDER BY
    B.OrdenBloque,
    T.OrdenTramite;
GO
