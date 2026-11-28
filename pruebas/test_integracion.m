function test_integracion()
% Prueba de integración: corre principal con la cámara sintética y sin ventana,
% recorriendo todas las operaciones, y revisa el CSV del recorrido.

% La raíz del repo es la carpeta padre de pruebas; al terminar se regresa a la carpeta actual
raiz = fileparts(fileparts(mfilename('fullpath')));
anterior = pwd;
regreso = onCleanup(@() cd(anterior));
cd(raiz);
carpeta = fullfile(raiz, 'resultados');

% CSV de recorridos que ya existían antes de correr
antes = dir(fullfile(carpeta, 'recorrido_*.csv'));
antes = {antes.name};

% Si principal lanza un error la prueba falla aquí mismo
principal(struct('sin_camara', true, 'sin_ventana', true, 'recorrer', true, 'cuadros_por_op', 5));

% Debe aparecer exactamente un CSV de recorrido nuevo
despues = dir(fullfile(carpeta, 'recorrido_*.csv'));
nuevos = setdiff({despues.name}, antes);
assert(numel(nuevos) == 1, 'Debe crearse un CSV de recorrido nuevo en resultados');

% Se lee el CSV línea por línea (la primera es el encabezado)
f = fopen(fullfile(carpeta, nuevos{1}), 'r', 'n', 'UTF-8');
encabezado = fgetl(f);
lineas = {};
linea = fgetl(f);
while ischar(linea)
    if ~isempty(strtrim(linea))
        lineas{end+1} = linea;
    end
    linea = fgetl(f);
end
fclose(f);

% Una fila por operación del registro (14)
assert(numel(lineas) == 14, sprintf('El CSV debe tener 14 filas de datos y tiene %d', numel(lineas)));

% Se busca la columna por nombre por si el CSV gana columnas nuevas
columnas = strsplit(encabezado, ',');
c_op = find(strcmp(columnas, 'mediana_ms_operacion'));
assert(numel(c_op) == 1, 'Falta la columna mediana_ms_operacion');

% El nombre va entre comillas y puede tener comas, así que se separa lo que sigue a la última comilla
for i = 1:numel(lineas)
    q = find(lineas{i} == '"', 1, 'last');
    valores = str2double(strsplit(lineas{i}(q+2:end), ','));
    mediana = valores(c_op - 1);
    assert(~isnan(mediana) && mediana > 0, sprintf('La mediana de operación de la fila %d no es positiva', i));
end

disp('OK test_integracion');
end
