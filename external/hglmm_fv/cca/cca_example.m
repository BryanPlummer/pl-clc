% ---- training the CCA model ----

% the input for the CCA training is the representations of all the correct 
% <sentence, image> pairs of the training set.
% so you should prepare 2 matrices, X_trn and Y_trn:
% X_trn: a d*n matrix where n is number of training sentences and d is the
%   dimension of sentence representation. this matrix contains the
%   representations of all training sentences.
% Y_trn: a m*n matrix where m is the dimension of image representation.
%   this matrix should satisfy that for all i, X_trn(:,i) and Y_trn(:,i)
%   are vectors of a correct <sentence, image> pair.


% X_trn = ...
% Y_trn = ...


% create an object of class CCAModel
cca_m = CCAModel;


% regularization value (should be determined using the validation set).
eta = 0.001;

% setting center to true enables centering of the data (reducing the mean)
% we got better results with centering enabled
center = true;

% train
lg(1, 'cca train start\n');
cca_m.train(X_trn, Y_trn, eta, center);
lg(1, 'cca train done\n');


% ---- mapping the test samples using the trained CCA model ----

% setting apply_r to true will enable scaling by the eigenvalues
% we got better results with this scaling
cca_m.set_apply_r(true);


% a matrix containing the vectors of the test sentences (each column is a
% vector representation of a sentence)
% tst_sentences = ...

% a matrix containing the vectors of the test images (each column is a
% vector representation of an image)
% tst_images = ...

% map the sentences vectors and normalize
tst_sentences = cca_m.map(tst_sentences, true, true);
% map the images vectors and normalize
tst_images = cca_m.map(tst_images, false, true);

% after this mapping, we used the cosine similarity to score the similarity
% between each image and each sentence



% ---- using our provided pre-trained CCA model ----

% below is an example for using our pre-trained CCA model, trained on the COCO dataset.
% this is the model which is referred to as GMM+HGLMM in our paper.
% this model expects the following image and sentence representations:
%   image representation: the usual VGG representation, as described in the file README.txt.
%   sentence representation: the GMM+HGLMM representation, which means concatenation of GMM FV
%     and HGLMM FV (both with 30 clusters, and both on top of ICA-transformed word2vec). due to memory
%     limitation, we had to reduce the representation dimension before CCA training. we did it
%     by random sampling of 20,000 coordinates out of 36,000. the code below examplifies this and
%     uses the same coordinate sample (which is the one that our CCA model expects).


% pre-trained CCA model file name (chage the folder to your own)
cca_model_file_name = '~/data/sentences_images/coco/cca_models_1/cca_model_g30i_h30i_eta_5e-05_cntr_1_sampled.mat';
% this will load a variable named cca_m of type CCAModel
load(cca_model_file_name);

% the sampled coordinates are stored in this file (chage the folder to your own)
sent_vec_sampled_features_file_name = '~/data/sentences_images/coco/sent_vec_sampled_features_g30i_h30i.mat';
% a varialbe named sent_vec_sampled_features will be loaded
load(sent_vec_sampled_features_file_name);

% in fv_example.m we have genereted hglmm_30_ica_sent_vecs (the needed HGLMM representation
% for sentences) and gmm_30_ica_sent_vecs (the needed GMM representation for sentences)
% now let's concatenate these representations:
tst_sentences = [gmm_30_ica_sent_vecs ; hglmm_30_ica_sent_vecs];

% now we apply the coordinate sampling explained above
tst_sentences = tst_sentences(sent_vec_sampled_features, :);

% now we can map the sentences vectors as shown in the previous example above:

cca_m.set_apply_r(true);
% map the sentences vectors and normalize
tst_sentences = cca_m.map(tst_sentences, true, true);

% and we can map images vectors as well:

% map the images vectors and normalize
tst_images = cca_m.map(tst_images, false, true);
