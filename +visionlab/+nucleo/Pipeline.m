classdef Pipeline
% Pipeline: aplica la operación activa al cuadro en gris y mide su tiempo.

    methods (Static)
        function [salida, t] = procesar(gris, op, estado)
            % Parámetros actuales; las de movimiento reciben también el cuadro anterior
            p = estado.p;
            if op.movimiento
                if isempty(estado.anterior)
                    p.anterior = gris;   % en el primer cuadro no hay anterior: se usa el mismo
                else
                    p.anterior = estado.anterior;
                end
            end

            % Se mide solo la operación (en ms)
            a = tic;
            salida = op.funcion(gris, p);
            t = 1000 * toc(a);

            estado.anterior = gris;
        end

        function img = a_despliegue(salida)
            % Las imágenes binarias se pasan a 0/255; uint8 gris o RGB se dejan igual
            if islogical(salida)
                img = uint8(salida) * 255;
            else
                img = salida;
            end
        end
    end
end
