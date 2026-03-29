-- ==========================================
-- 0. LIMPIEZA DEL ENTORNO
-- ==========================================

BEGIN
   -- Recorrer todas las tablas que pertenecen al usuario actual
   FOR rec IN (SELECT table_name FROM user_tables) LOOP
      -- Ejecutar el comando DROP para cada tabla encontrada
      -- CASCADE CONSTRAINTS: Borra las claves foráneas que apuntan a esta tabla
      -- PURGE: Borra la tabla definitivamente
      EXECUTE IMMEDIATE 'DROP TABLE "' || rec.table_name || '" CASCADE CONSTRAINTS PURGE';
   END LOOP;
   
   DBMS_OUTPUT.PUT_LINE('Todas las tablas han sido eliminadas correctamente.');
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error al intentar borrar las tablas: ' || SQLERRM);
END;

