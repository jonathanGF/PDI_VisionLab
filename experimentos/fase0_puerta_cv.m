% Fase 0 (variante): igual que fase0_puerta, pero captura con OpenCV a través
% del intérprete de Python embebido en MATLAB (pyenv). Sirve mientras no está
% instalado el paquete de webcam y como medición del costo de conversión y despliegue.
function fase0_puerta_cv(backend)
    if nargin < 1, backend = 'MSMF'; end
    % El entorno .venv con opencv-python solo hace falta si no está instalado el paquete de webcam
    raiz = fileparts(fileparts(mfilename('fullpath')));
    pyenv('Version', fullfile(raiz, '.venv', 'Scripts', 'python.exe'));
    cv = py.importlib.import_module('cv2');
    api = cv.CAP_MSMF; if strcmp(backend, 'DSHOW'), api = cv.CAP_DSHOW; end
    cap = cv.VideoCapture(int32(0), int32(api));
    cap.set(cv.CAP_PROP_FRAME_WIDTH, 640); cap.set(cv.CAP_PROP_FRAME_HEIGHT, 480);
    leer = @() leer_cuadro(cap);
    for k = 1:15, leer(); end

    fig = figure('Name', 'Fase 0 (OpenCV)', 'Color', 'w', 'Position', [100 100 1300 520]);
    ax1 = subplot(1, 2, 1); h1 = image(ax1, zeros(480, 640, 3, 'uint8')); axis(ax1, 'image', 'off'); title(ax1, 'Original');
    ax2 = subplot(1, 2, 2); h2 = image(ax2, zeros(480, 640, 'uint8')); colormap(ax2, gray(256)); axis(ax2, 'image', 'off'); title(ax2, 'Gris');
    drawnow;

    N = 200; t_cap = nan(1, N); t_gris = nan(1, N); t_disp = nan(1, N); unico = false(1, N);
    anterior = []; t_total = tic;
    for k = 1:N
        a = tic; rgb = leer(); t_cap(k) = toc(a);
        unico(k) = isempty(anterior) || ~isequal(rgb(1:8:end, 1:8:end, :), anterior);
        anterior = rgb(1:8:end, 1:8:end, :);
        b = tic; gris = uint8(0.299 * double(rgb(:,:,1)) + 0.587 * double(rgb(:,:,2)) + 0.114 * double(rgb(:,:,3))); t_gris(k) = toc(b);
        c = tic; set(h1, 'CData', rgb); set(h2, 'CData', gris); drawnow limitrate; t_disp(k) = toc(c);
    end
    T = toc(t_total); cap.release(); close(fig);

    ms = @(t) 1000 * median(t);
    fprintf('\n[%s] Cuadros: %d en %.2f s -> %.1f lecturas/s, %d únicos -> %.1f FPS únicos\n', backend, N, T, N/T, nnz(unico), nnz(unico)/T);
    fprintf('captura (OpenCV+conversión py->MATLAB): %.1f ms | a gris: %.1f ms | despliegue: %.1f ms | suma: %.1f ms\n', ms(t_cap), ms(t_gris), ms(t_disp), ms(t_cap)+ms(t_gris)+ms(t_disp));
    fprintf('criterio de la fase 0 (<= 25 ms): %s\n', string(ms(t_cap)+ms(t_gris)+ms(t_disp) <= 25));
end

function rgb = leer_cuadro(cap)
    r = cap.read(); fr = r{2};                       % numpy BGR 480x640x3
    b = uint8(fr.tobytes());                         % bytes -> uint8 (copia única)
    img = permute(reshape(b, [3 640 480]), [3 2 1]); % a 480x640x3
    rgb = img(:, :, [3 2 1]);                        % BGR -> RGB
end
