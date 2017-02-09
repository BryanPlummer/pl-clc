function writeFastRCNNProto(nClasses,outdir,indir)
%READCLASSESFROMFILE reads a class dictionary file from disk
%   inputs
%       nClasses - number of categories to output
%       outdir - directory to output the prototxt files to
%       indir - directory of the base prototxt files without the category
%               specific layers
    if nargin < 3
        indir = fullfile('models','stripped_proto');
    end
   
    nClasses = nClasses + 1; % +1 for background category
    mkdir_if_missing(outdir);
    test = strsplit(fileread(fullfile(indir,'test.prototxt')),'\n');
    newTestLayers = {getClsScore(nClasses),getBBoxPred(nClasses),getClsProb()};
    testProto = strcatWithDelimiter([test,newTestLayers],'\n');
    fileID = fopen([outdir,'/test.prototxt'],'w');
    fprintf(fileID,testProto);
    fclose(fileID);

    trainfn = 'train_val.prototxt';
    train = strsplit(fileread(fullfile(indir,trainfn)),'\n');
    newFileHead = {getROIInputs(),getBBRegInputs(nClasses)};
    newFileEnd = {getClsScore(nClasses),getBBoxPred(nClasses),getSoftmaxLoss(),getAcc(),getBoxLoss()};
    trainProto = strcatWithDelimiter([newFileHead,train,newFileEnd],'\n');
    fileID = fopen(fullfile(outdir,trainfn),'w');
    fprintf(fileID,trainProto);
    fclose(fileID);

    solver = strsplit(fileread(fullfile(indir,'solver.prototxt')),'\n');
    newFileHead = {getSolverHead(outdir,trainfn)};
    solverProto = strcatWithDelimiter([newFileHead,solver],'\n');
    fileID = fopen(fullfile(outdir,'solver.prototxt'),'w');
    fprintf(fileID,solverProto);
    fclose(fileID);
end

function clsString = getClsScore(nClasses)
    clsString = sprintf('layer {\n\tbottom: "fc7"\n\ttop: "cls_score"\n\tname: "cls_score"\n\tparam {\n\t\tlr_mult: 1.0\n\t}\n\tparam {\n\t\tlr_mult: 2.0\n\t}\n\ttype: "InnerProduct"\n\tinner_product_param {\n\t\tnum_output: %i\n\t\tweight_filler {\n\t\t\ttype: "gaussian"\n\t\t\tstd: 0.01\n\t\t}\n\t\tbias_filler {\n\t\t\ttype: "constant"\n\t\t\tvalue: 0\n\t\t}\n\t}\n}\n',nClasses);
end

function bboxString = getBBoxPred(nClasses)
    bboxString = sprintf('layer {\n\tbottom: "fc7"\n\ttop: "bbox_pred"\n\tname: "bbox_pred"\n\ttype: "InnerProduct"\n\tparam {\n\t\tlr_mult: 1.0\n\t}\n\tparam {\n\t\tlr_mult: 2.0\n\t}\n\tinner_product_param {\n\t\tnum_output: %i\n\t\tweight_filler {\n\t\t\ttype: "gaussian"\n\t\t\tstd: 0.001\n\t\t}\n\t\tbias_filler {\n\t\t\ttype: "constant"\n\t\t\tvalue: 0\n\t\t}\n\t}\n}\n',nClasses*4);
end

function probString = getClsProb()
    probString = 'layer {\n\tname: "cls_prob"\n\ttype: "Softmax"\n\tbottom: "cls_score"\n\ttop: "cls_prob"\n\tloss_weight: 1\n}\n';
end

function inputsString = getROIInputs()
    inputsString = 'name: "VGG_ILSVRC_16"\n\ninput: "data"\ninput_dim: 1\ninput_dim: 3\ninput_dim: 224\ninput_dim: 224\n\ninput: "rois"\ninput_dim: 1\ninput_dim: 5\ninput_dim: 1\ninput_dim: 1\n\ninput: "labels"\ninput_dim: 1\ninput_dim: 1\ninput_dim: 1\ninput_dim: 1';
end

function bbRegInputString = getBBRegInputs(nClasses)
    bbRegInputString = sprintf('input: "bbox_targets"\ninput_dim: 1\ninput_dim: %i\ninput_dim: 1\ninput_dim: 1\n\ninput: "bbox_loss_weights"\ninput_dim: 1\ninput_dim: %i\ninput_dim: 1\ninput_dim: 1',nClasses*4,nClasses*4);
end

function softmaxString = getSoftmaxLoss()
    softmaxString = 'layer {\n\tname: "loss"\n\ttype: "SoftmaxWithLoss"\n\tbottom: "cls_score"\n\tbottom: "labels"\n\ttop: "loss_cls"\n\tloss_weight: 1\n}\n';
end

function accString = getAcc()
    accString = 'layer {\n\tname: "accuarcy"\n\ttype: "Accuracy"\n\tbottom: "cls_score"\n\tbottom: "labels"\n\ttop: "accuarcy"\n}\n';
end

function boxLossString = getBoxLoss()
    boxLossString = 'layer {\n\tname: "loss_bbox"\n\ttype: "SmoothL1Loss"\n\tbottom: "bbox_pred"\n\tbottom: "bbox_targets"\n\tbottom: "bbox_loss_weights"\n\ttop: "loss_bbox"\n\tloss_weight: 1\n}\n';
end

function solverString = getSolverHead(outdir,trainfn)
    solverString = sprintf('net: "%s"\n',fullfile(outdir,trainfn));
end
