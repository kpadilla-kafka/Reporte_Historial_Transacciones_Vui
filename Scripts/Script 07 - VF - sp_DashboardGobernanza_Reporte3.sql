USE [VUI_TransaccionesDB];
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************
 Proyecto      : Dashboard Gobernanza
 Reporte       : Reporte 3

 Procedimiento : dbo.sp_DashboardGobernanza_Reporte3

 Descripción:
     Obtiene el histórico mensual de transacciones de la Ventanilla Única de
     Inversión (VUI), agrupadas por bloque, trámite y año.

     El procedimiento muestra:
        - "ST" para períodos anteriores a la fecha de habilitación del trámite.
        - "0" cuando el trámite estaba habilitado pero no tuvo transacciones.
        - La cantidad correspondiente cuando existen registros.

     Los parámetros Bloque y Trámite permiten recibir múltiples valores
     separados por el carácter "|" para su consumo desde SQL Server Reporting
     Services (SSRS).

 Ambiente:
     Desarrollo

 Parámetros:
     @FechaInicio : Fecha inicial obligatoria del rango a consultar.
     @FechaFin    : Fecha final obligatoria del rango a consultar.
     @Bloque      : Uno o varios nombres de bloque separados por "|".
                    Si recibe NULL o una cadena vacía, consulta todos.
     @Tramite     : Uno o varios nombres de trámite separados por "|".
                    Si recibe NULL o una cadena vacía, consulta todos.

 Resultado:
     Consecutivo
     OrdenBloque
     Bloque
     OrdenTramite
     Tramite
     Anio
     ENE
     FEB
     MAR
     ABR
     MAY
     JUN
     JUL
     AGO
     SEP
     OCT
     NOV
     DIC
     Cantidad

 Historial de cambios:
 ------------------------------------------------------------------------------
 Fecha        Autor               Descripción
 ----------  ------------------  -----------------------------------------------
 2026-07-09  Katiana Padilla     Creación inicial del procedimiento.
 2026-07-10  Katiana Padilla     Versión 2.0: soporte para selección múltiple
                                 de bloques y trámites desde SSRS.
 ------------------------------------------------------------------------------
******************************************************************************/

ALTER PROCEDURE [dbo].[sp_DashboardGobernanza_Reporte3]
(
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @Bloque NVARCHAR(MAX) = NULL,
    @Tramite NVARCHAR(MAX) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /*===========================================================
      1. Validación de parámetros obligatorios
    ===========================================================*/
    IF @FechaInicio IS NULL
    BEGIN
        RAISERROR(
            'La fecha inicial es obligatoria.',
            16,
            1
        );
        RETURN;
    END;

    IF @FechaFin IS NULL
    BEGIN
        RAISERROR(
            'La fecha final es obligatoria.',
            16,
            1
        );
        RETURN;
    END;

    IF @FechaInicio > @FechaFin
    BEGIN
        RAISERROR(
            'La fecha inicial no puede ser mayor que la fecha final.',
            16,
            1
        );
        RETURN;
    END;

    /*===========================================================
      2. Normalización de parámetros multivalor

         Los parámetros enviados desde SSRS tendrán esta forma:

         Bloque 1|Bloque 2|Bloque 3

         Una cadena vacía se interpreta como ausencia de filtro.
    ===========================================================*/
    SET @Bloque = NULLIF(LTRIM(RTRIM(@Bloque)), N'');
    SET @Tramite = NULLIF(LTRIM(RTRIM(@Tramite)), N'');

    /*===========================================================
      3. Generación del rango mensual
    ===========================================================*/
    ;WITH Meses AS
    (
        SELECT
            DATEFROMPARTS
            (
                YEAR(@FechaInicio),
                MONTH(@FechaInicio),
                1
            ) AS FechaMes

        UNION ALL

        SELECT
            DATEADD(MONTH, 1, FechaMes)
        FROM Meses
        WHERE FechaMes <
              DATEFROMPARTS
              (
                  YEAR(@FechaFin),
                  MONTH(@FechaFin),
                  1
              )
    ),

    /*===========================================================
      4. Base de trámites y meses

         Cruza los trámites activos con todos los meses del rango
         seleccionado y aplica los filtros multivalor.
    ===========================================================*/
    Base AS
    (
        SELECT
            B.OrdenBloque,
            B.Nombre AS Bloque,
            T.OrdenTramite,
            T.Nombre AS Tramite,
            T.FechaHabilitacion,
            YEAR(M.FechaMes) AS Anio,
            MONTH(M.FechaMes) AS Mes,
            M.FechaMes,
            EOMONTH(M.FechaMes) AS FinMes,
            T.VUI_Tramite
        FROM dbo.VUI_Tramite T
        INNER JOIN dbo.VUI_Bloque B
            ON B.VUI_Bloque = T.VUI_Bloque
        CROSS JOIN Meses M
        WHERE T.Activo = 1
          AND B.Activo = 1

          /* Filtro multivalor de bloques */
          AND
          (
              @Bloque IS NULL

              OR EXISTS
              (
                  SELECT 1
                  FROM STRING_SPLIT(@Bloque, N'|') SB
                  WHERE LTRIM(RTRIM(SB.value)) = B.Nombre
              )
          )

          /* Filtro multivalor de trámites */
          AND
          (
              @Tramite IS NULL

              OR EXISTS
              (
                  SELECT 1
                  FROM STRING_SPLIT(@Tramite, N'|') ST
                  WHERE LTRIM(RTRIM(ST.value)) = T.Nombre
              )
          )
    ),

    /*===========================================================
      5. Conteo real de transacciones por trámite, año y mes
    ===========================================================*/
    Conteo AS
    (
        SELECT
            TX.VUI_Tramite,
            YEAR(TX.FechaTransaccion) AS Anio,
            MONTH(TX.FechaTransaccion) AS Mes,
            COUNT(*) AS Cantidad
        FROM dbo.VUI_Transaccion TX
        WHERE TX.Activo = 1
          AND TX.FechaTransaccion >= @FechaInicio
          AND TX.FechaTransaccion <
              DATEADD(DAY, 1, @FechaFin)
        GROUP BY
            TX.VUI_Tramite,
            YEAR(TX.FechaTransaccion),
            MONTH(TX.FechaTransaccion)
    ),

    /*===========================================================
      6. Aplicación de la regla ST / 0 / Cantidad
    ===========================================================*/
    Resultado AS
    (
        SELECT
            B.OrdenBloque,
            B.Bloque,
            B.OrdenTramite,
            B.Tramite,
            B.Anio,
            B.Mes,

            CASE
                WHEN B.FechaHabilitacion IS NOT NULL
                 AND B.FinMes < B.FechaHabilitacion
                    THEN N'ST'

                ELSE CAST
                (
                    ISNULL(C.Cantidad, 0)
                    AS NVARCHAR(20)
                )
            END AS ValorMes,

            CASE
                WHEN B.FechaHabilitacion IS NOT NULL
                 AND B.FinMes < B.FechaHabilitacion
                    THEN 0

                ELSE ISNULL(C.Cantidad, 0)
            END AS ValorNumerico
        FROM Base B
        LEFT JOIN Conteo C
            ON C.VUI_Tramite = B.VUI_Tramite
           AND C.Anio = B.Anio
           AND C.Mes = B.Mes
    )

    /*===========================================================
      7. Salida final para SSRS
    ===========================================================*/
    SELECT
        ROW_NUMBER() OVER
        (
            PARTITION BY Bloque, Tramite
            ORDER BY Anio
        ) AS Consecutivo,

        OrdenBloque,
        Bloque,
        OrdenTramite,
        Tramite,
        Anio,

        MAX(CASE WHEN Mes = 1  THEN ValorMes END) AS ENE,
        MAX(CASE WHEN Mes = 2  THEN ValorMes END) AS FEB,
        MAX(CASE WHEN Mes = 3  THEN ValorMes END) AS MAR,
        MAX(CASE WHEN Mes = 4  THEN ValorMes END) AS ABR,
        MAX(CASE WHEN Mes = 5  THEN ValorMes END) AS MAY,
        MAX(CASE WHEN Mes = 6  THEN ValorMes END) AS JUN,
        MAX(CASE WHEN Mes = 7  THEN ValorMes END) AS JUL,
        MAX(CASE WHEN Mes = 8  THEN ValorMes END) AS AGO,
        MAX(CASE WHEN Mes = 9  THEN ValorMes END) AS SEP,
        MAX(CASE WHEN Mes = 10 THEN ValorMes END) AS OCT,
        MAX(CASE WHEN Mes = 11 THEN ValorMes END) AS NOV,
        MAX(CASE WHEN Mes = 12 THEN ValorMes END) AS DIC,

        SUM(ValorNumerico) AS Cantidad
    FROM Resultado
    GROUP BY
        OrdenBloque,
        Bloque,
        OrdenTramite,
        Tramite,
        Anio
    ORDER BY
        OrdenBloque,
        OrdenTramite,
        Anio
    OPTION (MAXRECURSION 0);
END;
GO
