# 💾 Crear máquina virtual para la base de datos

En este paso vamos a crear la máquina virtual que albergará la base de datos de nuestra aplicación Tour of Heroes.

## 🎯 Opciones disponibles

Tienes **dos opciones** para configurar la base de datos, dependiendo de tus recursos disponibles:

### 🐘 Opción 1: Ubuntu + PostgreSQL (Recomendada para cuentas gratuitas)

Si estás utilizando una **suscripción gratuita de Azure** o tienes limitaciones de vCores, esta es la opción más económica y sencilla de configurar. Utiliza una máquina virtual Ubuntu con PostgreSQL.

👉 [Ver guía de Ubuntu + PostgreSQL](README-ubuntu-postgresql.md)

**Ventajas:**
- ✅ Menor consumo de recursos (funciona con los cores de la versión gratuita)
- ✅ Sin costes de licencia
- ✅ Configuración más sencilla
- ✅ Ideal para entornos de desarrollo y aprendizaje

### 🪟 Opción 2: Windows + SQL Server

Si tienes una suscripción de pago o necesitas usar SQL Server específicamente, puedes utilizar esta opción que despliega una máquina virtual Windows con SQL Server.

👉 [Ver guía de Windows + SQL Server](README-windows-sqlserver.md)

**Ventajas:**
- ✅ Entorno empresarial más común
- ✅ Herramientas de administración más completas (SSMS)
- ✅ Mayor compatibilidad con aplicaciones .NET tradicionales

> ⚠️ **Nota**: Esta opción requiere más recursos y puede no funcionar con las limitaciones de vCores de las suscripciones gratuitas de Azure.

---

## 📊 Comparativa rápida

| Característica | Ubuntu + PostgreSQL | Windows + SQL Server |
|----------------|---------------------|----------------------|
| **Coste** | 💚 Bajo | 🟡 Medio-Alto |
| **Recursos mínimos** | 💚 Standard_DS1_v2 | 🟡 Standard_B2as_v2 |
| **Complejidad** | 💚 Baja | 🟡 Media |
| **Licencias** | 💚 Gratuito | 🟡 Incluida en imagen |
| **Ideal para** | Aprendizaje, Dev | Producción, Enterprise |

---

Una vez hayas creado la máquina virtual de base de datos con cualquiera de las dos opciones, puedes continuar con el siguiente paso: [Crear la VM de la API](../02-api-vm/README.md) 🚀
