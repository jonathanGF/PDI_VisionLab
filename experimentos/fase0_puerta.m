% Fase 0: puerta de desempeño. Mide, con la cámara integrada a 640x480,
% el costo por cuadro de: captura (snapshot), conversión a gris y despliegue
% con image + drawnow limitrate. Cuenta solo cuadros únicos (no repetidos).
% Criterio del diseño: captura + conversión + despliegue <= 25 ms por cuadro único.
function fase0_puerta()
    cam = webcam(1);
    try, cam.Resolution = '640x480'; catch, end
    disp(['Cámara: ' cam.Name ' @ ' cam.Resolution]);
    for k = 1:10, snapshot(cam); end          % calentamiento (autoexposición)

    fig = figure('Name', 'Fase 0', 'Color', 'w', 'Position', [100 100 1300 520]);
    ax1 = subplot(1, 2, 1); h1 = image(ax1, zeros(480, 640, 3, 'uint8')); axis(ax1, 'image', 'off'); title(ax1, 'Original');
    ax2 = subplot(1, 2, 2); h2 = image(ax2, zeros(480, 640, 'uint8')); colormap(ax2, gray(256)); axis(ax2, 'image', 'off'); title(ax2, 'Gris');
    drawnow;

    N = 200; t_cap = nan(1, N); t_gris = nan(1, N); t_disp = nan(1, N); unico = false(1, N);
    anterior = []; t_total = tic;
    for k = 1:N
        a = tic; rgb = snapshot(cam); t_cap(k) = toc(a);
        unico(k) = isempty(anterior) || ~isequal(rgb(1:8:end, 1:8:end, :), anterior);
        anterior = rgb(1:8:end, 1:8:end, :);
        b = tic; gris = uint8(0.299 * double(rgb(:,:,1)) + 0.587 * double(rgb(:,:,2)) + 0.114 * double(rgb(:,:,3))); t_gris(k) = toc(b);
        c = tic; set(h1, 'CData', rgb); set(h2, 'CData', gris); drawnow limitrate; t_disp(k) = toc(c);
    end
    T = toc(t_total); clear cam; close(fig);

    ms = @(t) 1000 * median(t);
    fprintf('\nCuadros: %d en %.2f s -> %.1f lecturas/s, %d únicos -> %.1f FPS únicos\n', N, T, N/T, nnz(unico), nnz(unico)/T);
    fprintf('captura (snapshot): %.1f ms | a gris: %.1f ms | despliegue: %.1f ms | suma: %.1f ms\n', ms(t_cap), ms(t_gris), ms(t_disp), ms(t_cap)+ms(t_gris)+ms(t_disp));
    fprintf('presupuesto a 20 FPS: 50 ms; criterio de la fase 0 (<= 25 ms): %s\n', string(ms(t_cap)+ms(t_gris)+ms(t_disp) <= 25));
end
