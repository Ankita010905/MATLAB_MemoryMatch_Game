function memoryMatchGame
    % Create GUI window
    fig = figure('Name', 'Memory Match Game', ...
        'Position', [300 100 400 500], ...
        'Color', 'white', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'CloseRequestFcn', @onClose);

    % Tile generation: 8 matching pairs
    tileValues = repmat(1:8, 1, 2);
    tileValues = tileValues(randperm(16));
    tileMatrix = reshape(tileValues, [4, 4])';

    % Game state data
    data.tileMatrix = tileMatrix;
    data.revealed = false(4,4);
    data.buttons = gobjects(4,4);
    data.flipped = [];
    data.locked = false;
    data.matched = 0;
    data.moves = 0;
    data.timerStart = [];
    data.timerObj = [];
    data.timePassed = 0;

    % Score display
    data.scoreText = uicontrol('Style', 'text', ...
        'Position', [30 440 120 30], ...
        'BackgroundColor', 'white', ...
        'FontSize', 12, ...
        'String', 'Moves: 0');

    % Timer display
    data.timerText = uicontrol('Style', 'text', ...
        'Position', [230 440 120 30], ...
        'BackgroundColor', 'white', ...
        'FontSize', 12, ...
        'String', 'Time: 0 s');

    guidata(fig, data);

    % Create tile buttons
    for i = 1:4
        for j = 1:4
            btn = uicontrol('Style', 'pushbutton', ...
                'Position', [50 + (j-1)*70, 350 - (i-1)*70, 60, 60], ...
                'FontSize', 16, ...
                'String', '', ...
                'Callback', @(src,~) tileCallback(src, i, j));
            data.buttons(i,j) = btn;
        end
    end

    % Start game timer (runs every 1 second)
    data.timerObj = timer('ExecutionMode', 'fixedRate', ...
        'Period', 1, ...
        'TimerFcn', @(~,~) updateTimer);
    guidata(fig, data);
end

%% --- Tile Click Callback ---
function tileCallback(src, row, col)
    data = guidata(gcf);

    % Start timer at first click
    if isempty(data.timerStart)
        data.timerStart = tic;
        start(data.timerObj);
    end

    if data.revealed(row,col) || data.locked
        return;
    end

    % Reveal clicked tile
    value = data.tileMatrix(row, col);
    set(src, 'String', num2str(value));
    data.revealed(row,col) = true;
    drawnow;

    if isempty(data.flipped)
        data.flipped = [row col];
    else
        data.locked = true;
        prev = data.flipped;
        pause(0.5);

        val1 = data.tileMatrix(prev(1), prev(2));
        val2 = data.tileMatrix(row, col);

        data.moves = data.moves + 1;
        set(data.scoreText, 'String', ['Moves: ', num2str(data.moves)]);

        if val1 == val2
            % Match
            set(data.buttons(prev(1), prev(2)), 'Enable', 'off', 'BackgroundColor', 'green');
            set(data.buttons(row, col), 'Enable', 'off', 'BackgroundColor', 'green');
            data.matched = data.matched + 1;
        else
            % No match
            set(data.buttons(prev(1), prev(2)), 'String', '');
            set(data.buttons(row, col), 'String', '');
            data.revealed(prev(1), prev(2)) = false;
            data.revealed(row, col) = false;
        end

        data.flipped = [];
        data.locked = false;
    end

    % Win condition
    if data.matched == 8
        stop(data.timerObj);
        elapsed = toc(data.timerStart);
        msgbox(sprintf('? You Won!\nMoves: %d\nTime: %.0f sec', ...
            data.moves, elapsed), 'Victory');
    end

    guidata(gcf, data);
end

%% --- Timer Update Function ---
function updateTimer
    if ~ishandle(gcf)
        return;
    end
    data = guidata(gcf);
    if ~isempty(data.timerStart)
        elapsed = round(toc(data.timerStart));
        set(data.timerText, 'String', ['Time: ', num2str(elapsed), ' s']);
    end
end

%% --- On Close ---
function onClose(~, ~)
    try
        d = guidata(gcf);
        if isfield(d, 'timerObj') && isvalid(d.timerObj)
            stop(d.timerObj);
            delete(d.timerObj);
        end
    catch
    end
    delete(gcf);
end
