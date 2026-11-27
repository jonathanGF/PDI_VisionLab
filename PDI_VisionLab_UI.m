function PDI_VisionLab_UI
% PDI_VisionLab_UI - Interfaz independiente para PDI VisionLab.
% Ejecutar desde la carpeta raiz del proyecto: PDI_VisionLab_UI

imgOriginal = [];       % Referencia limpia
imgEntrada = [];        % Imagen que se procesa (puede contener ruido)
imgProcesada = [];
ruidoGenerado = false;
camara = [];

C.bg = [0.055 0.075 0.11]; C.panel = [0.085 0.11 0.16];
C.panel2 = [0.11 0.14 0.20]; C.accent = [0.15 0.62 0.95];
C.accent2 = [0.12 0.78 0.68]; C.text = [0.93 0.96 1.00];
C.muted = [0.62 0.69 0.78]; C.border = [0.20 0.26 0.35];

fig = uifigure('Name','PDI VisionLab | Procesamiento Digital de Imagenes', ...
    'Position',[100 80 1280 780],'Color',C.bg,'Resize','on');

side = uipanel(fig,'Position',[0 0 270 780], ...
    'BackgroundColor',C.panel,'BorderType','none');
uilabel(side,'Position',[24 715 220 34],'Text','PDI VisionLab', ...
    'FontSize',24,'FontWeight','bold','FontColor',C.text);
uilabel(side,'Position',[25 690 220 22],'Text','IMAGE PROCESSING STUDIO', ...
    'FontSize',10,'FontWeight','bold','FontColor',C.accent);
uilabel(side,'Position',[24 638 220 24],'Text','ENTRADA DE IMAGEN', ...
    'FontSize',10,'FontWeight','bold','FontColor',C.muted);

makeButton(side,'Cargar imagen',[22 590 226 38],@loadImage,C.accent);
makeButton(side,'Capturar webcam',[22 542 226 38],@captureWebcam,C.panel2);
makeButton(side,'Restablecer original',[22 494 226 38],@resetImage,C.panel2);

uilabel(side,'Position',[24 450 220 24],'Text','PROCESAMIENTO', ...
    'FontSize',10,'FontWeight','bold','FontColor',C.muted);
uilabel(side,'Position',[24 416 220 20],'Text','Operacion', ...
    'FontSize',12,'FontColor',C.text);
ddOperacion = uidropdown(side,'Position',[22 386 226 30], ...
    'Items',{'Escala de grises','Umbralizacion','Filtro promedio 3x3', ...
    'Filtro gaussiano 3x3','Filtro mediana 3x3', ...
    'Agregar ruido gaussiano','Agregar ruido sal y pimienta'}, ...
    'Value','Escala de grises','BackgroundColor',C.panel2,'FontColor',C.text);

lblParametro = uilabel(side,'Position',[24 345 190 20], ...
    'Text','Umbral (0 - 255)','FontSize',12,'FontColor',C.text);
lblParametroValor = uilabel(side,'Position',[205 344 42 20],'Text','128', ...
    'FontSize',11,'FontColor',C.accent,'HorizontalAlignment','right');
slParametro = uislider(side,'Position',[28 330 210 3], ...
    'Limits',[0 255],'Value',128);
slParametro.ValueChangingFcn = @updateParameterValue;
ddOperacion.ValueChangedFcn = @updateParameterControl;

makeButton(side,'Aplicar procesamiento',[22 270 226 42],@processImage,C.accent2);
uilabel(side,'Position',[24 218 220 24],'Text','EVALUACION VS. REFERENCIA LIMPIA', ...
    'FontSize',9,'FontWeight','bold','FontColor',C.muted);
lblMSE = uilabel(side,'Position',[24 185 220 22],'Text','MSE: --', ...
    'FontSize',12,'FontColor',C.text);
lblPSNR = uilabel(side,'Position',[24 158 220 22],'Text','PSNR: --', ...
    'FontSize',12,'FontColor',C.text);
makeButton(side,'Guardar resultado',[22 92 226 38],@saveResult,C.panel2);
uilabel(side,'Position',[24 24 225 42], ...
    'Text','Proyecto academico | MATLAB R2026a', ...
    'FontSize',9,'FontColor',C.muted);

main = uipanel(fig,'Position',[270 0 1010 780], ...
    'BackgroundColor',C.bg,'BorderType','none');
uilabel(main,'Position',[32 718 900 34], ...
    'Text','Laboratorio de procesamiento digital de imagenes', ...
    'FontSize',21,'FontWeight','bold','FontColor',C.text);
uilabel(main,'Position',[34 692 900 20], ...
    'Text','Carga una imagen, agrega ruido y compara los filtros', ...
    'FontSize',11,'FontColor',C.muted);

p1 = uipanel(main,'Position',[30 150 455 510], ...
    'BackgroundColor',C.panel,'BorderType','line','HighlightColor',C.border);
p2 = uipanel(main,'Position',[505 150 475 510], ...
    'BackgroundColor',C.panel,'BorderType','line','HighlightColor',C.border);
uilabel(p1,'Position',[18 468 410 24],'Text','IMAGEN DE ENTRADA', ...
    'FontSize',11,'FontWeight','bold','FontColor',C.muted);
uilabel(p2,'Position',[18 468 430 24],'Text','RESULTADO PROCESADO', ...
    'FontSize',11,'FontWeight','bold','FontColor',C.muted);
axOriginal = uiaxes(p1,'Position',[15 15 425 440], ...
    'Color',C.panel,'XColor',C.panel,'YColor',C.panel);
axProcesada = uiaxes(p2,'Position',[15 15 445 440], ...
    'Color',C.panel,'XColor',C.panel,'YColor',C.panel);
axis(axOriginal,'off'); axis(axProcesada,'off');

lblEstado = uilabel(main,'Position',[32 105 930 25], ...
    'Text','Listo. Carga una imagen o captura desde la webcam.', ...
    'FontSize',11,'FontColor',C.accent2);
uilabel(main,'Position',[32 65 930 22], ...
    'Text','Las metricas comparan la salida con la referencia limpia, no solo con la entrada ruidosa.', ...
    'FontSize',9,'FontColor',C.muted);

updateParameterControl();

    function loadImage(~,~)
        [f,p] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif','Archivos de imagen'}, ...
            'Seleccionar imagen');
        if isequal(f,0), return; end
        try
            imgOriginal = imread(fullfile(p,f));
            imgEntrada = imgOriginal;
            imgProcesada = [];
            ruidoGenerado = false;
            showImages(); updateMetrics();
            set(lblEstado,'Text',['Imagen cargada: ' f],'FontColor',C.accent2);
        catch ME
            uialert(fig,ME.message,'No se pudo cargar la imagen');
        end
    end

    function captureWebcam(~,~)
        try
            if isempty(camara), camara = webcam; end
            imgOriginal = snapshot(camara);
            imgEntrada = imgOriginal;
            imgProcesada = [];
            ruidoGenerado = false;
            showImages(); updateMetrics();
            set(lblEstado,'Text','Nueva captura obtenida desde la webcam.','FontColor',C.accent2);
        catch ME
            uialert(fig,['No fue posible acceder a la webcam. Verifica la conexion y los permisos.' newline newline ME.message], ...
                'Error de camara');
        end
    end

    function resetImage(~,~)
        if isempty(imgOriginal)
            set(lblEstado,'Text','Primero carga o captura una imagen.','FontColor',[1 0.65 0.3]);
            return;
        end
        imgEntrada = imgOriginal;
        imgProcesada = [];
        ruidoGenerado = false;
        showImages(); updateMetrics();
        set(lblEstado,'Text','Se restauro la imagen original limpia.','FontColor',C.accent2);
    end

    function updateParameterControl(~,~)
        op = ddOperacion.Value;
        switch op
            case 'Umbralizacion'
                lblParametro.Text = 'Umbral (0 - 255)';
                slParametro.Limits = [0 255]; slParametro.Value = 128;
                slParametro.Enable = 'on';
            case 'Agregar ruido gaussiano'
                lblParametro.Text = 'Sigma (0 - 50 niveles)';
                slParametro.Limits = [0 50]; slParametro.Value = 15;
                slParametro.Enable = 'on';
            case 'Agregar ruido sal y pimienta'
                lblParametro.Text = 'Densidad (0 - 0.20)';
                slParametro.Limits = [0 0.20]; slParametro.Value = 0.05;
                slParametro.Enable = 'on';
            otherwise
                lblParametro.Text = 'Parametro no utilizado';
                slParametro.Limits = [0 255]; slParametro.Value = 128;
                slParametro.Enable = 'off';
        end
        updateParameterText(slParametro.Value);
    end

    function updateParameterValue(~,event)
        updateParameterText(event.Value);
    end

    function updateParameterText(value)
        if strcmp(ddOperacion.Value,'Agregar ruido sal y pimienta')
            lblParametroValor.Text = sprintf('%.2f',value);
        else
            lblParametroValor.Text = sprintf('%.0f',value);
        end
    end

    function processImage(~,~)
        if isempty(imgOriginal)
            uialert(fig,'Primero carga una imagen o captura desde la webcam.','No hay imagen');
            return;
        end
        try
            op = ddOperacion.Value;

            % La generacion de ruido siempre parte de la referencia limpia.
            if strcmp(op,'Agregar ruido gaussiano')
                base = im2double(imgOriginal);
                sigma = slParametro.Value / 255;
                noisy = min(max(base + sigma .* randn(size(base)),0),1);
                imgEntrada = im2uint8(noisy);
                imgProcesada = [];
                ruidoGenerado = true;
                showImages(); updateMetrics();
                set(lblEstado,'Text',sprintf('Ruido gaussiano agregado (sigma = %.0f/255).',slParametro.Value), ...
                    'FontColor',C.accent2);
                return;
            elseif strcmp(op,'Agregar ruido sal y pimienta')
                density = slParametro.Value;
                imgEntrada = addSaltPepper(imgOriginal,density);
                imgProcesada = [];
                ruidoGenerado = true;
                showImages(); updateMetrics();
                set(lblEstado,'Text',sprintf('Ruido sal y pimienta agregado (densidad = %.2f).',density), ...
                    'FontColor',C.accent2);
                return;
            end

            % Los filtros trabajan sobre la entrada actual, que puede tener ruido.
            I = im2uint8(imgEntrada);
            switch op
                case 'Escala de grises'
                    if ndims(I)==2
                        imgProcesada = I;
                    else
                        imgProcesada = rgb2gray(I(:,:,1:3));
                    end
                case 'Umbralizacion'
                    if ndims(I)==2
                        Igray = I;
                    else
                        Igray = rgb2gray(I(:,:,1:3));
                    end
                    imgProcesada = im2uint8(im2double(Igray) >= slParametro.Value/255);
                case 'Filtro promedio 3x3'
                    imgProcesada = applyPerChannel(I,ones(3,3)/9);
                case 'Filtro gaussiano 3x3'
                    imgProcesada = applyPerChannel(I,fspecial('gaussian',[3 3],0.8));
                case 'Filtro mediana 3x3'
                    imgProcesada = medianPerChannel(I);
            end
            showImages(); updateMetrics();
            set(lblEstado,'Text',['Operacion aplicada: ' op], ...
                'FontColor',C.accent2);
        catch ME
            uialert(fig,ME.message,'Error de procesamiento');
        end
    end

    function J = addSaltPepper(I,density)
        % Aplica el mismo impulso a todos los canales de cada pixel.
        J = im2uint8(I);
        [h,w,channels] = size(J);
        randomMap = rand(h,w);
        pepper = randomMap < density/2;
        salt = randomMap >= density/2 & randomMap < density;
        for channel = 1:channels
            plane = J(:,:,channel);
            plane(pepper) = 0;
            plane(salt) = 255;
            J(:,:,channel) = plane;
        end
    end

    function J = applyPerChannel(I,h)
        if ndims(I)==2
            J = im2uint8(imfilter(im2double(I),h,'replicate'));
        else
            J = zeros(size(I),'uint8');
            for c = 1:size(I,3)
                J(:,:,c) = im2uint8(imfilter(im2double(I(:,:,c)),h,'replicate'));
            end
        end
    end


function J = medianPerChannel(I)
    % Utiliza nuestro algoritmo propio de mediana 3x3.

    if ndims(I) == 2
        % Adaptar imagen en escala de grises a RGB
        I_rgb = repmat(I,1,1,3);

        % Ejecutar algoritmo propio
        J_rgb = visionlab.algoritmos.filtrado.filtro_mediana(I_rgb);

        % Recuperar un solo canal
        J = J_rgb(:,:,1);

    else
        % Trabajar con los tres canales RGB
        I_rgb = I(:,:,1:3);

        J = visionlab.algoritmos.filtrado.filtro_mediana(I_rgb);
    end
end

    function showImages()
        cla(axOriginal); cla(axProcesada);
        if isempty(imgOriginal), return; end

        if isempty(imgEntrada)
            entradaActual = imgOriginal;
        else
            entradaActual = imgEntrada;
        end
        imshow(entradaActual,'Parent',axOriginal);

        if isempty(imgProcesada)
            imshow(entradaActual,'Parent',axProcesada);
            title(axProcesada,'Sin procesar','Color',C.muted,'FontWeight','normal');
        else
    imshow(imgProcesada,'Parent',axProcesada);
    title(axProcesada,ddOperacion.Value, ...
        'Color',C.muted,'FontWeight','normal');
    end
        axis(axOriginal,'image'); axis(axProcesada,'image');
        axis(axOriginal,'off'); axis(axProcesada,'off');
    end

    function updateMetrics()
        if isempty(imgOriginal)
            set(lblMSE,'Text','MSE: --'); set(lblPSNR,'Text','PSNR: --');
            return;
        end

        if ~isempty(imgProcesada)
            candidate = imgProcesada;
        elseif ruidoGenerado
            candidate = imgEntrada;
        else
            set(lblMSE,'Text','MSE: --'); set(lblPSNR,'Text','PSNR: --');
            return;
        end

        A = im2double(imgOriginal);
        B = im2double(candidate);
        if ndims(A)==3, A = rgb2gray(A(:,:,1:3)); end
        if ndims(B)==3, B = rgb2gray(B(:,:,1:3)); end
        if ~isequal(size(A),size(B))
            set(lblMSE,'Text','MSE: dimensiones incompatibles');
            set(lblPSNR,'Text','PSNR: --');
            return;
        end

        mse = mean((A(:)-B(:)).^2);
        if mse==0, psnrValue=Inf; else, psnrValue=10*log10(1/mse); end
        set(lblMSE,'Text',sprintf('MSE: %.6f',mse));
        if isinf(psnrValue)
            set(lblPSNR,'Text','PSNR: Inf dB');
        else
            set(lblPSNR,'Text',sprintf('PSNR: %.2f dB',psnrValue));
        end
    end

    function saveResult(~,~)
        if isempty(imgProcesada)
            uialert(fig,'Aplica primero un filtro para obtener un resultado que puedas guardar.','Sin resultado');
            return;
        end
        [f,p] = uiputfile({'*.png','Imagen PNG';'*.jpg','Imagen JPEG'}, ...
            'Guardar imagen procesada','resultado_PDI.png');
        if isequal(f,0), return; end
        try
            imwrite(imgProcesada,fullfile(p,f));
            set(lblEstado,'Text',['Resultado guardado: ' f],'FontColor',C.accent2);
        catch ME
            uialert(fig,ME.message,'No se pudo guardar');
        end
    end

    function makeButton(parent,txt,pos,callback,color)
        uibutton(parent,'push','Text',txt,'Position',pos, ...
            'ButtonPushedFcn',callback,'BackgroundColor',color, ...
            'FontColor',[1 1 1],'FontSize',12,'FontWeight','bold');
    end

fig.CloseRequestFcn = @closeApp;
    function closeApp(~,~)
        try
            if ~isempty(camara)
                clear camara;
            end
        catch
        end
        delete(fig);
    end
end
