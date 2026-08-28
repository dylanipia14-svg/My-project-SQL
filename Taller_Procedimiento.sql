CREATE SCHEMA IF NOT EXISTS Ventas;
-- creamos tablas 
CREATE TABLE IF NOT EXISTS ventas.clientes (
Id_cliente INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
nombre VARCHAR(100) NOT NULL,
correo VARCHAR(120) NOT NULL UNIQUE,
ciudad VARCHAR(80) NOT NULL,
activo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS Ventas.Productos (
Id_Producto INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
nombre VARCHAR(120) NOT NULL,
precio NUMERIC(12,2) NOT NULL CHECK (precio > 0),
stock INTEGER NOT NULL CHECK (stock >= 0),
activo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS Ventas.Pedidos (
Id_pedido INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
Id_Cliente INTEGER NOT NULL REFERENCES Ventas.clientes(Id_cliente),
fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
CHECK (estado IN ('PENDIENTE','PAGADO','CANCELADO')),
total NUMERIC(12,2) NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS Ventas.detalle_Pedido(
Id_detalle INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
Id_pedido INTEGER NOT NULL REFERENCES Ventas.Pedidos(Id_pedido),
Id_Producto INTEGER NOT NULL REFERENCES Ventas.Productos(Id_Producto),
cantidad INTEGER NOT NULL CHECK (cantidad > 0),
precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario > 0),
subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0)
);
-- Cargemos los Data YT
INSERT INTO ventas.clientes ( nombre, correo, ciudad)
VALUES
('Ana Torres', 'ana@correo.com', 'Cali'),
('Luis Gómez', 'luis@correo.com', 'Bogotá'),
('Marta Díaz', 'marta@correo.com', 'Medellín');

INSERT INTO ventas.productos ( nombre, precio, stock )
VALUES
('Portátil Lenovo', 2500000, 8),
('Mouse inalámbrico', 85000, 30),
('Teclado mecánico', 210000, 12),
('Monitor 24 pulgadas', 780000, 4);
-- hasta aqui insertamos los datos 
SELECT * FROM ventas.clientes;
SELECT * FROM Ventas.Productos;
SELECT * FROM  Ventas.Pedidos ;
-- Consultamos YT
-- Y creamos procedimientos 
CREATE OR REPLACE PROCEDURE Ventas.registrar_cliente(
  IN p_nombre VARCHAR(100),
  IN p_correo VARCHAR(120),
  IN p_ciudad VARCHAR(80)
)

LANGUAGE plpgsql
AS $$
BEGIN
INSERT INTO Ventas.clientes (  nombre, correo, ciudad, activo
)
VALUES (
   p_nombre,
   p_correo,
   p_ciudad,
TRUE
);

RAISE NOTICE 'Cliente % registrado correctamente', p_nombre;
END ;
$$;
-- Verificamos
CALL Ventas.registrar_cliente(
  'Carlos Pérez',
  'Carlos@gmail.com',
  'Cali'
);
-- Comprobammos sí se guardó
SELECT * FROM Ventas.clientes
WHERE correo = 'Carlos@gmail.com';
-- Si nos salio LET'S GO LET'S GO

CREATE OR REPLACE PROCEDURE Ventas.consultar_stock_producto(
  IN p_id_producto INTEGER,
  OUT p_nombre_producto VARCHAR(120),
  OUT p_stock INTEGER,
  OUT p_estado VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
-- Intentamos consultar el producto directamente
    SELECT nombre, stock 
    INTO p_nombre_producto, p_stock
    FROM ventas.productos
    WHERE id_producto = p_id_producto;

    -- Si la consulta no devuelve ningún registro
	-- un poquito de logica
IF NOT FOUND THEN
        p_nombre_producto := NULL;
        p_stock := NULL;
        p_estado := 'NO EXISTE';
ELSIF p_stock = 0 THEN
        p_estado := 'AGOTADO';
ELSE
        p_estado := 'DISPONIBLE';
    END IF;
END;
$$;

-- Prueba
CALL Ventas.consultar_stock_producto(1, NULL, NULL, NULL);
CALL Ventas.consultar_stock_producto(999, NULL, NULL, NULL);
-- Si salio 

CREATE OR REPLACE PROCEDURE ventas.clasificar_inventario_producto(
    IN p_id_producto INTEGER,
    OUT p_nombre_producto VARCHAR(120),
    OUT p_stock INTEGER,
    OUT p_clasificacion VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT nombre, stock 
    INTO p_nombre_producto, p_stock
    FROM ventas.productos
    WHERE Id_producto = p_Id_producto;

IF NOT FOUND THEN
p_nombre_producto := NULL;
p_stock := NULL;
p_clasificacion := 'NO EXISTE';
ELSIF p_stock = 0 THEN
p_clasificacion := 'AGOTADO';
ELSIF p_stock BETWEEN 1 AND 5 THEN
p_clasificacion := 'STOCK CRÍTICO';
ELSIF p_stock BETWEEN 6 AND 15 THEN
p_clasificacion := 'STOCK BAJO';
ELSE
      p_clasificacion := 'STOCK SUFICIENTE';
END IF;
END;
$$;

-- Pruebas esperadas YT
CALL ventas.clasificar_inventario_producto(1, NULL, NULL, NULL);
CALL ventas.clasificar_inventario_producto(4, NULL, NULL, NULL);
CALL ventas.clasificar_inventario_producto(999, NULL, NULL, NULL);
-- Esta tabien salio igual con NULL
-- Crear pedido y devolver su identificador YT
CREATE OR REPLACE PROCEDURE ventas.crear_pedido(
    IN p_id_cliente INTEGER,
    OUT p_id_pedido INTEGER,
    OUT p_mensaje VARCHAR(150)
)

LANGUAGE plpgsql
AS $$
DECLARE
    v_activo BOOLEAN;
BEGIN
    -- Consultar el estado activo del cliente
    SELECT activo 
    INTO v_activo
    FROM ventas.clientes
    WHERE id_cliente = p_id_cliente;

IF NOT FOUND THEN
        p_id_pedido := NULL;
        p_mensaje := 'Cliente no existe';
		ELSIF v_activo = FALSE THEN
        p_id_pedido := NULL;
        p_mensaje := 'Cliente inactivo';
ELSE
-- Insertamos DATA
        INSERT INTO ventas.pedidos (id_cliente, estado, total)
        VALUES (p_id_cliente, 'PENDIENTE', 0)
        RETURNING id_pedido INTO p_id_pedido;

        p_mensaje := 'Pedido creado correctamente';
    END IF;
END;
$$;

-- Pruebas esperadas 
CALL ventas.crear_pedido(1, NULL, NULL);
CALL ventas.crear_pedido(999, NULL, NULL);
-- Aqui tambien funciono JAJA
-- Reto adicional muchos errores 
-- Hacemos otra INSERT
INSERT INTO ventas.clientes (nombre, correo, ciudad, activo) 
VALUES ('Prueba Inactivo', 'inactivo@correo.com', 'Cali', FALSE);
-- Verificamos
CALL ventas.crear_pedido(4, NULL, NULL);

-- Verificación de pedidos YT
SELECT * FROM ventas.pedidos ORDER BY id_pedido DESC;
-- Hasta esta parte le mando segun lo que entendi 
-- bueno aunque ya estaba realizado pero daba muchos errores
-- Se trato de entender Gracias
-- La ultima parte se la subo estos dias 