% Fase 0 (complemento): propiedades de la cámara y efecto de la exposición
% sobre la tasa de cuadros únicos con el paquete de webcam.
function fase0_exposicion()
    cam = webcam(1);
    disp('Propiedades disponibles:'); disp(cam);
    medir(cam, '1280x720 (default)');
    cam.Resolution = '640x480';
    medir(cam, '640x480 (auto exposición)');
    try
        cam.ExposureMode = 'manual';
        for e = [-5 -6 -7]
            try
                cam.Exposure = e;
                medir(cam, sprintf('640x480 manual, Exposure = %d', e));
            catch err, fprintf('Exposure = %d no aceptado: %s\n', e, err.message); end
        end
        cam.ExposureMode = 'auto';
    catch err
        fprintf('Sin control de exposición: %s\n', err.message);
    end
    clear cam;
end

function medir(cam, etiqueta)
    for k = 1:8, snapshot(cam); end
    N = 60; t = zeros(1, N); unico = false(1, N); ant = []; brillo = 0; t0 = tic;
    for k = 1:N
        a = tic; f = snapshot(cam); t(k) = toc(a);
        s = f(1:8:end, 1:8:end, :); unico(k) = isempty(ant) || ~isequal(s, ant); ant = s; brillo = brillo + mean(f(:));
    end
    T = toc(t0);
    fprintf('%-36s snapshot %6.1f ms | %5.1f lecturas/s | %5.1f FPS únicos | brillo medio %5.1f\n', etiqueta, 1000*median(t), N/T, nnz(unico)/T, brillo/N);
end
