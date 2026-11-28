% Fase 0 (complemento): exposición manual compensada con brillo y gamma.
function fase0_brillo()
    cam = webcam(1); cam.Resolution = '640x480';
    cam.ExposureMode = 'manual';
    casos = { -4, 50, 50;  -4, 100, 50;  -4, 100, 100;  -5, 100, 50;  -5, 100, 100;  -5, 100, 150 };
    for i = 1:size(casos, 1)
        try
            cam.Exposure = casos{i,1}; cam.Brightness = casos{i,2}; cam.Gamma = casos{i,3};
            medir(cam, sprintf('Exposure %d, Brightness %d, Gamma %d', casos{i,:}));
        catch err, fprintf('caso %d no aceptado: %s\n', i, err.message); end
    end
    cam.ExposureMode = 'auto'; cam.Brightness = 50; cam.Gamma = 50;
    medir(cam, 'auto (referencia)');
    clear cam;
end
function medir(cam, etiqueta)
    for k = 1:8, snapshot(cam); end
    N = 45; t = zeros(1, N); unico = false(1, N); ant = []; brillo = 0; t0 = tic;
    for k = 1:N
        a = tic; f = snapshot(cam); t(k) = toc(a);
        s = f(1:8:end, 1:8:end, :); unico(k) = isempty(ant) || ~isequal(s, ant); ant = s; brillo = brillo + mean(f(:));
    end
    T = toc(t0);
    fprintf('%-40s snapshot %6.1f ms | %5.1f FPS únicos | brillo medio %5.1f\n', etiqueta, 1000*median(t), nnz(unico)/T, brillo/N);
end
