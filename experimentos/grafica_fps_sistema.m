function grafica_fps_sistema()
% Gráfica de barras con los FPS únicos del sistema completo por operación
% (captura + gris + operación + despliegue), leída del recorrido con la cámara.
% Lee y escribe en documentacion/experimentos/figuras/.

raiz = fileparts(fileparts(mfilename('fullpath')));
carpeta = fullfile(raiz, 'documentacion', 'experimentos', 'figuras');

% El CSV lo genera principal(struct('recorrer', true)) y se copia como recorrido_camara.csv
t = readtable(fullfile(carpeta, 'recorrido_camara.csv'), 'TextType', 'char', 'Encoding', 'UTF-8');
n = height(t);

% Barras con los FPS y la línea del objetivo de 20 FPS
fig = figure('Visible', 'off', 'Position', [100 100 1100 600]);
bar(t.fps_unicos);
hold on;
plot([0 n + 1], [20 20], 'r--', 'LineWidth', 1.5);
hold off;
xlim([0 n + 1]);
ylim([0 1.15 * max(t.fps_unicos)]);
set(gca, 'XTick', 1:n, 'XTickLabel', t.operacion, 'XTickLabelRotation', 40);
ylabel('FPS únicos');
title('Sistema completo con la cámara: FPS únicos por operación (640x480, 60 cuadros cada una)');
legend({'FPS únicos', 'objetivo 20 FPS'}, 'Location', 'southwest');
grid on;

% El valor encima de cada barra
for i = 1:n
    text(i, t.fps_unicos(i) + 0.5, sprintf('%.1f', t.fps_unicos(i)), 'HorizontalAlignment', 'center');
end

print(fig, fullfile(carpeta, 'fps_sistema.png'), '-dpng', '-r120');
close(fig);
fprintf('Gráfica: %s\n', fullfile(carpeta, 'fps_sistema.png'));
end
