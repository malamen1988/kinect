require 'torch'
require 'image'

datasetDir = 'rgbd-dataset'

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function dirsize(objects)
	local i, popen = torch.Tensor(#objects), io.popen
	for n = 1,#objects do
		i[n] = 0
		for filename in popen('ls -a "'..datasetDir..'/'..objects[n]..'"'):lines() do
			if (filename ~= '.' and filename ~= '..') then
				for datafile in popen('ls -a "'..datasetDir..'/'..objects[n]..'/'..filename..'"'):lines() do
					if string.ends(datafile,'_crop.png') then i[n] = i[n] + 1 end
				end
			end
		end
	end
	return i
end

-- Lua implementation of PHP scandir function
function scandir(objects, trdata, tedata, trlabels, telabels)
	local i, popen = 0, io.popen
	local label
	trstep = 0
	testep = 0
	for n = 1,#objects do
		print('... loading ' .. size[n] .. ' ' .. objects[n] .. 's')
		i = 1
		j = 1

		trs = math.floor(size[n]*.8)
		tes = size[n]-trs

		for filename in popen('ls -a "'..datasetDir..'/'..objects[n]..'"'):lines() do
			if (filename ~= '.' and filename ~= '..') then
				for datafile in popen('ls -a "'..datasetDir..'/'..objects[n]..'/'..filename..'"'):lines() do
					if string.ends(datafile,'_crop.png') then
						im = image.load(datasetDir..'/'..objects[n]..'/'..filename..'/'..datafile)
						im = image.scale(im, 32, 32, 'simple')
						
						if i<=trs then
							trdata[i + trstep] = im
							trlabels[i + trstep] = n
							i = i + 1
						elseif j<=tes then
							tedata[j + testep] = im
							telabels[j + testep] = n
							j = j + 1
						end
						
					end
				end
			end
		end
		trstep = trstep + i-1
		testep = testep + j-1
	end
	return trdata, tedata, trlabels, telabels
end

function loadData(objects)
	-- print ('#objects ' .. #objects)
	size = dirsize(objects)

	trsize = 0
	tesize = 0

	if opt.size == 'full' then
		print '==> using all training data'
		for i=1,#objects do
			local tr = math.floor(size[i]*.8)
			trsize = trsize + tr
			tesize = tesize + size[i] - tr
		end
	elseif opt.size == 'small' then
	   print '==> using reduced training data, for fast experiments'
	   for i=1,#objects do
	   		size[i] = math.min(size[i],2000)
			local tr = math.floor(size[i]*.8)
			trsize = trsize + tr
			tesize = tesize + size[i] - tr
		end
	end

	local trdata = torch.Tensor(trsize,3,32,32)
	local tedata = torch.Tensor(tesize,3,32,32)
	local trlabels = torch.Tensor(trsize)
	local telabels = torch.Tensor(tesize)

	scandir(objects, trdata, tedata, trlabels, telabels)

	local trainData = {
	   data = trdata,
	   labels = trlabels,
	   size = function() return trsize end
	}

	local testData = {
	   data = tedata,
	   labels = telabels,
	   size = function() return tesize end
	}
	
	return trainData, testData
end

-- trainData, testData = loadData({'apple','banana'})

-- print(trainData)
-- print(testData)