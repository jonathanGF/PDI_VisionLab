% Corredor de pruebas de PDI VisionLab: ejecuta todos los test_*.m

function resultado = correr_pruebas()

% Carpeta de pruebas y raíz del repo (carpeta padre)
carpeta = fileparts(mfilename('fullpath'));
raiz = fileparts(carpeta);
cd(raiz);
addpath(carpeta);

% Busca los archivos test_*.m
archivos = dir(fullfile(carpeta, 'test_*.m'));
n = numel(archivos);
nombres = cell(n, 1);
estado = cell(n, 1);
mensajes = cell(n, 1);

fprintf('\nPruebas de PDI VisionLab\n\n');
fprintf('%-32s %-6s %s\n', 'Prueba', 'Estado', 'Mensaje');

for k = 1:n
    % Nombre sin la extensión .m
    [~, nom] = fileparts(archivos(k).name);
    nombres{k} = nom;
    try
        feval(nom);
        estado{k} = 'OK';
        mensajes{k} = '';
    catch err
        estado{k} = 'FALLA';
        % Mensaje en una sola línea y recortado para la tabla
        msj = strrep(err.message, sprintf('\n'), ' ');
        if numel(msj) > 70
            msj = [msj(1:67) '...'];
        end
        mensajes{k} = msj;
    end
    fprintf('%-32s %-6s %s\n', nombres{k}, estado{k}, mensajes{k});
end

% Total de pruebas correctas
correctas = sum(strcmp(estado, 'OK'));
fprintf('\nTotal: %d de %d pruebas OK\n\n', correctas, n);

resultado = struct('nombres', {nombres}, 'estado', {estado}, 'mensajes', {mensajes});
end
