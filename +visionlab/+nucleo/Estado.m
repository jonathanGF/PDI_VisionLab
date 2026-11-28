classdef Estado < handle
% Estado compartido entre la interfaz y el lazo principal.
% La interfaz escribe aquí y el lazo lo lee en cada cuadro.

    properties
        op = 1            % índice de la operación activa en el registro
        p = struct()      % valor actual de cada parámetro de la operación activa
        corriendo = true  % se pone en false al cerrar la ventana
        anterior = []     % cuadro anterior en gris (para operaciones de movimiento)
    end

    methods
        function cambiar_operacion(obj, k, ops)
            % Activa la operación k y pone sus parámetros en el valor inicial
            obj.op = k;
            obj.p = struct();
            par = ops(k).parametros;
            for i = 1:numel(par)
                obj.p.(par(i).nombre) = par(i).inicial;
            end
            obj.anterior = [];
        end
    end
end
