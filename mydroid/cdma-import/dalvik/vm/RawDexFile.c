/*
 * Copyright (C) 2008 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/*
 * Open an unoptimized DEX file.
 */
#include "Dalvik.h"

/*
 * Open an unoptimized DEX file.  This finds the optimized version in the
 * cache, constructing it if necessary.
 */
int dvmRawDexFileOpen(const char* fileName, RawDexFile** ppRawDexFile,
    bool isBootstrap)
{
    // TODO - should be very similar to what JarFile does
    return -1;
}

/*
 * Close a RawDexFile and free the struct.
 */
void dvmRawDexFileFree(RawDexFile* pRawDexFile)
{
    if (pRawDexFile == NULL)
        return;

    dvmDexFileFree(pRawDexFile->pDvmDex);
    free(pRawDexFile->cacheFileName);
    free(pRawDexFile);
}
